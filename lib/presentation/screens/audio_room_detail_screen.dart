import 'dart:async';

import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:livekit_client/livekit_client.dart';

import '../../core/api/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/session_models.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/common_app_bar.dart';

class AudioRoomDetailScreen extends ConsumerStatefulWidget {
  final String roomId;

  const AudioRoomDetailScreen({
    super.key,
    required this.roomId,
  });

  @override
  ConsumerState<AudioRoomDetailScreen> createState() =>
      _AudioRoomDetailScreenState();
}

class _AudioRoomDetailScreenState
    extends ConsumerState<AudioRoomDetailScreen> {
  SessionDetailsModel? _details;
  bool _loading = true;
  bool _joiningLive = false;
  String? _errorMessage;
  String? _livekitError;
  Timer? _pollTimer;
  Room? _room;
  VoidCallback? _roomListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadDetails());
    });
    _pollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => unawaited(_loadDetails(silent: true)),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    unawaited(_disconnectRoom());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final user = ref.watch(userProvider);
    final details = _details;

    return Scaffold(
      appBar: const CommonAppBar(title: 'تفاصيل الجلسة'),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.screenGradient(isDark),
        ),
        child: _loading && details == null
            ? Center(
                child: CircularProgressIndicator(
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
              )
            : details == null
                ? _buildErrorState(isDark)
                : RefreshIndicator(
                    onRefresh: () => _loadDetails(),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
                      children: [
                        _buildHeroCard(isDark, details),
                        const SizedBox(height: 16),
                        _buildAccessCard(isDark, details, user != null),
                        const SizedBox(height: 16),
                        _buildActionsCard(isDark, details, user != null),
                        if (details.handRaises.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _buildHandRaisesCard(isDark, details),
                        ],
                        const SizedBox(height: 16),
                        _buildParticipantsCard(
                          isDark,
                          details,
                          user?.id ?? '',
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Future<void> _loadDetails({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final details = await ref
          .read(sessionRepositoryProvider)
          .getSessionDetails(widget.roomId);

      if (!mounted) {
        return;
      }

      setState(() {
        _details = details;
        _errorMessage = null;
      });

      if (!details.session.isLive && _room != null) {
        await _disconnectRoom();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted && !silent) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _joinLiveRoom() async {
    final user = ref.read(userProvider);
    if (user == null) {
      context.go('/auth');
      return;
    }

    if (_joiningLive) {
      return;
    }

    setState(() {
      _joiningLive = true;
      _livekitError = null;
    });

    try {
      final joinResult =
          await ref.read(sessionRepositoryProvider).joinSession(widget.roomId);

      await _loadDetails(silent: true);

      if (joinResult.token == null || joinResult.token!.isEmpty) {
        throw Exception(
          joinResult.session.isLive
              ? 'لم يصل رمز LiveKit لهذه الجلسة.'
              : 'تم تسجيلك في الجلسة، وسيظهر الدخول عند بدء البث.',
        );
      }

      await _disconnectRoom();

      final room = Room(
        roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true),
      );

      final listener = () {
        if (mounted) {
          setState(() {});
        }
      };
      room.addListener(listener);
      _roomListener = listener;

      await room.connect(ApiConfig.livekitBaseUrl, joinResult.token!);
      await room.startAudio();
      await room.setSpeakerOn(true);

      if (joinResult.access.canPublish) {
        await room.localParticipant?.setMicrophoneEnabled(true);
      }

      if (!mounted) {
        await room.disconnect();
        await room.dispose();
        return;
      }

      setState(() {
        _room = room;
      });

      _showSnack('تم تجهيز دخولك إلى البث.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _livekitError = error.toString().replaceFirst('Exception: ', '');
      });
      _showSnack(_livekitError!, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _joiningLive = false;
        });
      }
    }
  }

  Future<void> _disconnectRoom() async {
    final room = _room;
    if (room == null) {
      return;
    }

    if (_roomListener != null) {
      room.removeListener(_roomListener!);
      _roomListener = null;
    }

    try {
      await room.disconnect();
    } catch (_) {}

    try {
      await room.dispose();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _room = null;
      });
    }
  }

  Future<void> _registerForSession() async {
    await _performSimpleJoin('تم تسجيلك في الجلسة بنجاح.');
  }

  Future<void> _leaveSession() async {
    try {
      await ref.read(sessionRepositoryProvider).leaveSession(widget.roomId);
      await _disconnectRoom();
      await _loadDetails(silent: true);
      _refreshSessionLists();
      _showSnack('تم تحديث حالة انضمامك.');
    } catch (error) {
      _showSnack(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _performSimpleJoin(String successMessage) async {
    try {
      await ref.read(sessionRepositoryProvider).joinSession(widget.roomId);
      await _loadDetails(silent: true);
      _refreshSessionLists();
      _showSnack(successMessage);
    } catch (error) {
      _showSnack(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _runRoomAction({
    required String action,
    String? targetUserId,
    required String successMessage,
    bool disconnectAfter = false,
  }) async {
    try {
      final details = await ref.read(sessionRepositoryProvider).applyAction(
            sessionId: widget.roomId,
            action: action,
            targetUserId: targetUserId,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _details = details;
      });

      if (disconnectAfter) {
        await _disconnectRoom();
      }

      _refreshSessionLists();
      _showSnack(successMessage);
    } catch (error) {
      _showSnack(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _toggleMicrophone() async {
    final room = _room;
    if (room == null) {
      return;
    }

    try {
      final shouldEnable = room.localParticipant?.isMuted ?? true;
      await room.localParticipant?.setMicrophoneEnabled(shouldEnable);
      if (mounted) {
        setState(() {});
      }
    } catch (error) {
      _showSnack(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  void _refreshSessionLists() {
    ref.invalidate(sessionListProvider(null));
    ref.invalidate(sessionListProvider('live'));
    ref.invalidate(sessionListProvider('scheduled'));
    ref.invalidate(sessionListProvider('ended'));
    ref.invalidate(sessionDetailsProvider(widget.roomId));
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 46, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              'تعذر تحميل الجلسة',
              style: TextStyle(
                color: AppColors.textPrimary(isDark),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'حدث خطأ غير متوقع.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary(isDark),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadDetails(),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(bool isDark, SessionDetailsModel details) {
    final scheduledAt = details.session.scheduledAt.toLocal();
    final dateLabel = DateFormat('dd MMM yyyy - HH:mm').format(scheduledAt);
    final statusLabel = switch (details.session.status) {
      'live' => 'مباشر الآن',
      'ended' => 'منتهية',
      _ => 'قيد الجدولة',
    };

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient(isDark),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _heroChip(statusLabel),
              const Spacer(),
              Icon(
                details.session.visibility == 'restricted'
                    ? Icons.lock_outline
                    : Icons.public_outlined,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            details.session.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          if ((details.session.description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              details.session.description!,
              style: TextStyle(
                color: Colors.white.withAlpha(222),
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _heroChip(details.room.host.name),
              _heroChip('${details.participants.length} مشارك'),
              _heroChip(dateLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessCard(
    bool isDark,
    SessionDetailsModel details,
    bool userSignedIn,
  ) {
    final connectionState = _room?.connectionState;
    final connectionLabel = switch (connectionState) {
      ConnectionState.connected => 'متصل بالبث',
      ConnectionState.connecting => 'جارٍ الاتصال',
      ConnectionState.reconnecting => 'إعادة الاتصال',
      ConnectionState.disconnected => 'غير متصل',
      null => details.session.isLive ? 'جاهز للدخول' : 'بانتظار بدء البث',
    };

    return _sectionCard(
      isDark: isDark,
      title: 'ملخص الوصول',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _infoChip(isDark, Icons.badge_outlined,
                  'دورك: ${_roomRoleLabel(details.access.roomRole)}'),
              _infoChip(
                  isDark, Icons.headphones_outlined, connectionLabel),
              _infoChip(
                isDark,
                Icons.how_to_reg_outlined,
                details.access.isRegistered ? 'مسجل' : 'غير مسجل',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            !userSignedIn ? 'سجل الدخول أولًا لعرض وصولك الفعلي.' : _accessMessage(details),
            style: TextStyle(
              color: AppColors.textSecondary(isDark),
              height: 1.6,
            ),
          ),
          if (_livekitError != null && _livekitError!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _livekitError!,
              style: const TextStyle(
                color: AppColors.error,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsCard(
    bool isDark,
    SessionDetailsModel details,
    bool userSignedIn,
  ) {
    final isConnected = _room?.connectionState == ConnectionState.connected;
    final micEnabled = _room?.localParticipant != null
        ? !(_room!.localParticipant!.isMuted)
        : false;
    final currentUserId = ref.read(userProvider)?.id ?? '';
    final currentParticipant = details.participants
        .where((item) => item.id == currentUserId)
        .firstOrNull;
    final hasRaisedHand = currentParticipant?.hasRaisedHand ?? false;

    final buttons = <Widget>[];

    if (!userSignedIn && details.access.denialReason == 'AUTH_REQUIRED') {
      buttons.add(_actionButton('تسجيل الدخول', Icons.login, () => context.go('/auth')));
    } else if (details.session.isLive) {
      buttons.add(
        _actionButton(
          isConnected ? 'أنت داخل البث' : (_joiningLive ? 'جارٍ تجهيز الدخول' : 'ادخل البث'),
          Icons.radio,
          _joiningLive || isConnected ? null : _joinLiveRoom,
          destructive: true,
        ),
      );
    } else if (details.access.isRegistered) {
      buttons.add(
        _actionButton(
          'إلغاء التسجيل',
          Icons.event_busy_outlined,
          _leaveSession,
          outlined: true,
        ),
      );
    } else if (details.access.canJoin) {
      buttons.add(_actionButton('سجل الآن', Icons.event_available_outlined, _registerForSession));
    }

    if (details.access.canStartSession) {
      buttons.add(
        _actionButton(
          'ابدأ البث',
          Icons.play_circle_outline,
          () => _runRoomAction(
            action: 'start_live',
            successMessage: 'تم بدء البث الصوتي.',
          ),
        ),
      );
    }

    if (details.access.canEndSession) {
      buttons.add(
        _actionButton(
          'إنهاء الجلسة',
          Icons.stop_circle_outlined,
          () => _runRoomAction(
            action: 'end_session',
            successMessage: 'تم إنهاء الجلسة.',
            disconnectAfter: true,
          ),
          outlined: true,
        ),
      );
    }

    if (isConnected && details.access.canPublish) {
      buttons.add(
        _actionButton(
          micEnabled ? 'كتم الميكروفون' : 'فتح الميكروفون',
          micEnabled ? Icons.mic_off_outlined : Icons.mic_none_outlined,
          _toggleMicrophone,
          outlined: true,
        ),
      );
    }

    if (details.session.isLive &&
        details.access.isRegistered &&
        !details.access.canSpeak) {
      buttons.add(
        _actionButton(
          hasRaisedHand ? 'إلغاء رفع اليد' : 'رفع اليد',
          Icons.pan_tool_alt_outlined,
          hasRaisedHand
              ? () => _runRoomAction(
                    action: 'lower_hand',
                    successMessage: 'تم إلغاء طلب التحدث.',
                  )
              : () => _runRoomAction(
                    action: 'raise_hand',
                    successMessage: 'تم إرسال طلب التحدث.',
                  ),
          outlined: true,
        ),
      );
    }

    return _sectionCard(
      isDark: isDark,
      title: 'الإجراءات',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: buttons.isEmpty
            ? [
                Text(
                  'لا توجد إجراءات متاحة الآن لهذه الجلسة.',
                  style: TextStyle(color: AppColors.textSecondary(isDark)),
                ),
              ]
            : buttons,
      ),
    );
  }

  Widget _buildHandRaisesCard(bool isDark, SessionDetailsModel details) {
    return _sectionCard(
      isDark: isDark,
      title: 'طلبات التحدث',
      child: Column(
        children: details.handRaises
            .map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.subtleFill(isDark),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    _avatar(isDark, item.avatarUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          color: AppColors.textPrimary(isDark),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _runRoomAction(
                        action: 'accept_hand',
                        targetUserId: item.userId,
                        successMessage: 'تم قبول طلب التحدث.',
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      color: AppColors.success,
                    ),
                    IconButton(
                      onPressed: () => _runRoomAction(
                        action: 'reject_hand',
                        targetUserId: item.userId,
                        successMessage: 'تم رفض طلب التحدث.',
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      color: AppColors.error,
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildParticipantsCard(
    bool isDark,
    SessionDetailsModel details,
    String currentUserId,
  ) {
    final activeSpeakerIds =
        _room?.activeSpeakers.map((participant) => participant.identity).toSet() ??
            <String>{};

    return _sectionCard(
      isDark: isDark,
      title: 'المشاركون',
      child: Column(
        children: details.participants
            .map(
              (participant) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.subtleFill(isDark),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    _avatar(isDark, participant.avatarUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  participant.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.textPrimary(isDark),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (participant.id == currentUserId) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '(أنت)',
                                  style: TextStyle(
                                    color: AppColors.textSecondary(isDark),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _participantSubtitle(participant, activeSpeakerIds),
                            style: TextStyle(
                              color: AppColors.textSecondary(isDark),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (participant.hasRaisedHand)
                      Icon(
                        Icons.pan_tool_alt_outlined,
                        color: AppColors.warning,
                        size: 18,
                      ),
                    if (_participantActions(details.access, participant, currentUserId).isNotEmpty)
                      PopupMenuButton<String>(
                        onSelected: (value) => _runRoomAction(
                          action: value,
                          targetUserId: participant.id,
                          successMessage: _participantActionMessage(value),
                        ),
                        itemBuilder: (context) => _participantActions(
                          details.access,
                          participant,
                          currentUserId,
                        )
                            .map(
                              (item) => PopupMenuItem<String>(
                                value: item.$1,
                                child: Text(item.$2),
                              ),
                            )
                            .toList(),
                      ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  String _accessMessage(SessionDetailsModel details) {
    final denialReason = details.access.denialReason;
    if (denialReason != null) {
      return switch (denialReason) {
        'AUTH_REQUIRED' => 'يلزم تسجيل الدخول قبل الانضمام.',
        'SESSION_NOT_APPROVED' => 'هذه الجلسة ما زالت بانتظار الاعتماد.',
        'SESSION_ENDED' => 'هذه الجلسة انتهت بالفعل.',
        'SESSION_FULL' => 'وصلت الجلسة إلى الحد الأقصى من الحضور.',
        'SUBSCRIPTION_REQUIRED' => 'هذه الجلسة تتطلب اشتراكًا فعالًا.',
        _ => 'الوصول غير متاح لهذه الجلسة حاليًا.',
      };
    }

    if (details.session.isLive && details.access.canJoin) {
      return 'يمكنك الانضمام الآن إلى البث، وسيصدر الباكند رمز LiveKit حسب دورك الفعلي.';
    }

    if (!details.session.isLive && details.access.canJoin) {
      return details.access.isRegistered
          ? 'تم تسجيلك في هذه الجلسة، وسيظهر الدخول عند بدء البث.'
          : 'يمكنك التسجيل الآن ليكون دخولك جاهزًا عند بدء البث.';
    }

    return 'حالة الوصول ستظهر هنا حسب حالة الجلسة وصلاحيات الحساب.';
  }

  String _participantSubtitle(
    SessionParticipantModel participant,
    Set<String> activeSpeakerIds,
  ) {
    final roleLabel = _roomRoleLabel(participant.roomRole);
    if (activeSpeakerIds.contains(participant.id)) {
      return '$roleLabel - يتحدث الآن';
    }
    return roleLabel;
  }

  List<(String, String)> _participantActions(
    SessionAccessModel access,
    SessionParticipantModel participant,
    String currentUserId,
  ) {
    if (participant.id == currentUserId || participant.isHost) {
      return const [];
    }

    final actions = <(String, String)>[];

    if (access.canPromoteSpeaker && participant.roomRole == 'listener') {
      actions.add(('promote_speaker', 'ترقية إلى متحدث'));
    }
    if (access.canPromoteSpeaker &&
        const {'speaker', 'moderator', 'co_host'}.contains(participant.roomRole)) {
      actions.add(('demote_listener', 'إعادة إلى المستمعين'));
    }
    if (access.canPromoteModerator && participant.roomRole != 'moderator') {
      actions.add(('promote_moderator', 'ترقية إلى مشرف'));
    }
    if (access.canPromoteCoHost && participant.roomRole != 'co_host') {
      actions.add(('promote_co_host', 'ترقية إلى مضيف مشارك'));
    }
    if (access.canKick) {
      actions.add(('kick', 'طرد من الجلسة'));
    }

    return actions;
  }

  String _participantActionMessage(String action) {
    return switch (action) {
      'promote_speaker' => 'تمت ترقية المستخدم إلى متحدث.',
      'demote_listener' => 'تمت إعادة المستخدم إلى المستمعين.',
      'promote_moderator' => 'تمت ترقية المستخدم إلى مشرف.',
      'promote_co_host' => 'تمت ترقية المستخدم إلى مضيف مشارك.',
      'kick' => 'تم طرد المستخدم من الجلسة.',
      _ => 'تم تنفيذ الإجراء.',
    };
  }

  Widget _sectionCard({
    required bool isDark,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panelColor(isDark),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderColor(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _heroChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(20),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _infoChip(bool isDark, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.subtleFill(isDark),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.appBarForeground(isDark)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textPrimary(isDark),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    VoidCallback? onPressed, {
    bool destructive = false,
    bool outlined = false,
  }) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ],
    );

    if (outlined) {
      return OutlinedButton(onPressed: onPressed, child: child);
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: destructive
          ? ElevatedButton.styleFrom(backgroundColor: Colors.redAccent)
          : null,
      child: child,
    );
  }

  Widget _avatar(bool isDark, String? avatarUrl) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.panelColor(isDark),
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null
          ? Icon(
              Icons.person_outline,
              color: AppColors.appBarForeground(isDark),
            )
          : null,
    );
  }
}

String _roomRoleLabel(String roomRole) {
  return switch (roomRole) {
    'host' => 'المضيف',
    'co_host' => 'مضيف مشارك',
    'moderator' => 'مشرف',
    'speaker' => 'متحدث',
    'listener' => 'مستمع',
    _ => 'ضيف',
  };
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

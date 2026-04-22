import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../core/theme/app_colors.dart';
import '../../data/models/session_models.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/common_app_bar.dart';
import '../widgets/pulsing_dot.dart';

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

class _AudioRoomDetailScreenState extends ConsumerState<AudioRoomDetailScreen> {
  static const bool _traceLivekit =
      bool.fromEnvironment('TRACE_LIVEKIT', defaultValue: false);
  static const Duration _autoTokenRefreshCooldown = Duration(seconds: 12);

  SessionDetailsModel? _details;
  bool _loading = true;
  bool _joiningLive = false;
  bool _refreshingToken = false;
  bool _tokenCanPublish = false;
  bool _everConnectedToLivekit = false;
  DateTime? _lastAutoTokenRefreshAt;
  String? _errorMessage;
  String? _livekitError;
  Timer? _pollTimer;
  lk.Room? _room;
  VoidCallback? _roomListener;

  void _trace(String message, {Map<String, Object?> data = const {}}) {
    if (!_traceLivekit) {
      return;
    }

    final payload = <String, Object?>{
      'sessionId': widget.roomId,
      ...data,
    };

    dev.log('$message ${jsonEncode(payload)}', name: 'tartelea.livekit');
  }

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
    final previousAccess = _details?.access;

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

      await _maybeSyncLivekitToken(previousAccess, details);

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

  Future<void> _maybeSyncLivekitToken(
    SessionAccessModel? previousAccess,
    SessionDetailsModel details,
  ) async {
    final room = _room;
    if (room == null) {
      return;
    }

    if (!details.session.isLive) {
      return;
    }

    if (room.connectionState != lk.ConnectionState.connected) {
      return;
    }

    if (_refreshingToken || _joiningLive) {
      return;
    }

    final backendCanPublish = details.access.canPublish;
    final tokenCanPublish = _tokenCanPublish;

    if (backendCanPublish == tokenCanPublish) {
      return;
    }

    final now = DateTime.now();
    final lastAttempt = _lastAutoTokenRefreshAt;
    if (lastAttempt != null &&
        now.difference(lastAttempt) < _autoTokenRefreshCooldown) {
      _trace(
        'token_refresh_skipped_cooldown',
        data: {
          'userId': ref.read(userProvider)?.id,
          'backendRole': details.access.roomRole,
          'backendCanPublish': backendCanPublish,
          'tokenCanPublish': tokenCanPublish,
          'livekitIdentity': room.localParticipant?.identity,
          'connectionState': room.connectionState.toString(),
        },
      );
      return;
    }

    _lastAutoTokenRefreshAt = now;

    final accessChanged = previousAccess == null ||
        previousAccess.canPublish != backendCanPublish;
    if (accessChanged) {
      _showSnack(
        backendCanPublish
            ? 'تمت ترقيتك إلى متحدث، جارٍ إعادة الاتصال…'
            : 'تم تغيير دورك إلى مستمع، جارٍ تحديث الاتصال…',
      );
    }

    _trace(
      'token_refresh_auto_triggered',
      data: {
        'userId': ref.read(userProvider)?.id,
        'backendRole': details.access.roomRole,
        'backendCanPublish': backendCanPublish,
        'tokenCanPublish': tokenCanPublish,
        'livekitIdentity': room.localParticipant?.identity,
        'connectionState': room.connectionState.toString(),
      },
    );

    await _refreshLivekitTokenAndReconnect(reason: 'role_mismatch_auto');
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
      _trace(
        'join_live_request_token',
        data: {
          'userId': user.id,
          'livekitIdentityBefore': _room?.localParticipant?.identity,
        },
      );

      final tokenResult = await ref
          .read(sessionRepositoryProvider)
          .getLivekitToken(widget.roomId);

      _trace(
        'join_live_token_response',
        data: {
          'userId': user.id,
          'responseRole': tokenResult.role,
          'responseCanPublish': tokenResult.canPublish,
        },
      );

      await _loadDetails(silent: true);

      await _connectLivekitRoom(
        tokenResult,
        enableMicrophone: tokenResult.canPublish,
      );

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

  Future<void> _refreshLivekitTokenAndReconnect({
    bool enableMicrophoneAfter = false,
    String reason = 'manual',
  }) async {
    final user = ref.read(userProvider);
    if (user == null) {
      context.go('/auth');
      return;
    }

    if (_refreshingToken || _joiningLive) {
      return;
    }

    setState(() {
      _refreshingToken = true;
      _livekitError = null;
    });

    _trace(
      'token_refresh_start',
      data: {
        'userId': user.id,
        'reason': reason,
        'enableMicrophoneAfter': enableMicrophoneAfter,
        'tokenCanPublishBefore': _tokenCanPublish,
        'livekitIdentityBefore': _room?.localParticipant?.identity,
      },
    );

    try {
      final tokenResult = await ref
          .read(sessionRepositoryProvider)
          .getLivekitToken(widget.roomId);

      _trace(
        'token_refresh_response',
        data: {
          'userId': user.id,
          'reason': reason,
          'responseRole': tokenResult.role,
          'responseCanPublish': tokenResult.canPublish,
        },
      );

      await _connectLivekitRoom(
        tokenResult,
        enableMicrophone: enableMicrophoneAfter,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _trace(
        'token_refresh_failed',
        data: {
          'userId': user.id,
          'reason': reason,
          'error': error.toString(),
        },
      );
      setState(() {
        _livekitError = error.toString().replaceFirst('Exception: ', '');
      });
      _showSnack(_livekitError!, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _refreshingToken = false;
        });
      }
    }
  }

  Future<void> _connectLivekitRoom(
    LivekitTokenModel tokenResult, {
    required bool enableMicrophone,
  }) async {
    if (tokenResult.token.isEmpty) {
      throw Exception('لم يصل رمز LiveKit لهذه الجلسة.');
    }

    if (tokenResult.url.isEmpty) {
      throw Exception('لم يصل رابط LiveKit لهذه الجلسة.');
    }

    await _disconnectRoom();

    final room = lk.Room(
      roomOptions: const lk.RoomOptions(adaptiveStream: true, dynacast: true),
    );

    void listener() {
      if (mounted) {
        setState(() {});
      }
    }

    room.addListener(listener);
    _roomListener = listener;

    await room.connect(tokenResult.url, tokenResult.token);
    await room.startAudio();
    await room.setSpeakerOn(true);

    if (tokenResult.canPublish && enableMicrophone) {
      await room.localParticipant?.setMicrophoneEnabled(true);
    }

    final localIdentity = room.localParticipant?.identity;
    final livekitCanPublish = room.localParticipant?.permissions.canPublish;

    if (!mounted) {
      await room.disconnect();
      await room.dispose();
      return;
    }

    setState(() {
      _room = room;
      _tokenCanPublish = tokenResult.canPublish;
      _everConnectedToLivekit = true;
    });

    _trace(
      'livekit_connected',
      data: {
        'userId': ref.read(userProvider)?.id,
        'livekitIdentity': localIdentity,
        'tokenCanPublish': tokenResult.canPublish,
        'livekitCanPublish': livekitCanPublish,
        'enableMicrophone': enableMicrophone,
      },
    );
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
      _trace(
        'session_action_request',
        data: {
          'userId': ref.read(userProvider)?.id,
          'action': action,
          'targetUserId': targetUserId,
        },
      );

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

      _trace(
        'session_action_response',
        data: {
          'userId': ref.read(userProvider)?.id,
          'action': action,
          'targetUserId': targetUserId,
          'backendRole': details.access.roomRole,
          'backendCanPublish': details.access.canPublish,
        },
      );

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

    if (_refreshingToken) {
      return;
    }

    // Avoid attempting to publish with a listener-grade token.
    final details = _details;
    if (details != null && details.access.canPublish && !_tokenCanPublish) {
      _trace(
        'mic_requested_token_listener',
        data: {
          'userId': ref.read(userProvider)?.id,
          'backendRole': details.access.roomRole,
          'backendCanPublish': details.access.canPublish,
          'tokenCanPublish': _tokenCanPublish,
          'livekitIdentity': room.localParticipant?.identity,
        },
      );
      await _refreshLivekitTokenAndReconnect(
        enableMicrophoneAfter: true,
        reason: 'mic_request',
      );
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
    final statusColor = switch (details.session.status) {
      'live' => const Color(0xFFFF3B30),
      'ended' => Colors.white.withAlpha(190),
      _ => isDark ? AppColors.darkPrimary : AppColors.accent,
    };
    final activeSpeakerIds = _room?.activeSpeakers
            .map((participant) => participant.identity)
            .toSet() ??
        <String>{};

    final preview = <SessionParticipantModel>[];
    final seen = <String>{};
    for (final participant in details.participants) {
      if (participant.id.isEmpty) continue;
      if (!seen.add(participant.id)) continue;
      preview.add(participant);
      if (preview.length >= 6) break;
    }

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
              _heroAvatar(
                details.room.host.avatarUrl,
                isActive: activeSpeakerIds.contains(details.room.hostId),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details.room.host.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: Colors.white.withAlpha(210),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _statusDot(statusColor, pulsing: details.session.status == 'live'),
              const SizedBox(width: 10),
              Icon(
                details.session.visibility == 'restricted'
                    ? Icons.lock_outline
                    : Icons.public_outlined,
                color: Colors.white,
                size: 18,
              ),
              const Spacer(),
              _heroChip('${details.participants.length} مشارك'),
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
          Row(
            children: [
              Expanded(
                  child:
                      _heroAvatarStack(preview, activeSpeakerIds, statusColor)),
              const SizedBox(width: 12),
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
      lk.ConnectionState.connected => 'متصل بالبث',
      lk.ConnectionState.connecting => 'جارٍ الاتصال',
      lk.ConnectionState.reconnecting => 'إعادة الاتصال',
      lk.ConnectionState.disconnected => 'غير متصل',
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
              _infoChip(isDark, Icons.headphones_outlined, connectionLabel),
              _infoChip(
                isDark,
                Icons.how_to_reg_outlined,
                details.access.isRegistered ? 'مسجل' : 'غير مسجل',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            !userSignedIn
                ? 'سجل الدخول أولًا لعرض وصولك الفعلي.'
                : _accessMessage(details),
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
    final connectionState = _room?.connectionState;
    final isConnected = connectionState == lk.ConnectionState.connected;
    final isConnecting = connectionState == lk.ConnectionState.connecting;
    final isReconnecting = connectionState == lk.ConnectionState.reconnecting;
    final micEnabled = _room?.localParticipant != null
        ? !(_room!.localParticipant!.isMuted)
        : false;
    final tokenCanPublish = _tokenCanPublish;
    final publishMismatch =
        details.session.isLive && details.access.canPublish && !tokenCanPublish;
    final revokeMismatch =
        details.session.isLive && !details.access.canPublish && tokenCanPublish;
    final showTokenNotice = _refreshingToken ||
        (_everConnectedToLivekit && (publishMismatch || revokeMismatch));
    final currentUserId = ref.read(userProvider)?.id ?? '';
    final currentParticipant = details.participants
        .where((item) => item.id == currentUserId)
        .firstOrNull;
    final hasRaisedHand = currentParticipant?.hasRaisedHand ?? false;

    String primaryLabel = 'غير متاح';
    IconData primaryIcon = Icons.lock_outline;
    VoidCallback? primaryAction;
    bool primaryOutlined = true;
    Color primaryColor = isDark ? AppColors.darkPrimary : AppColors.accent;
    bool primaryBusy = false;

    final secondaryButtons = <Widget>[];

    if (!userSignedIn && details.access.denialReason == 'AUTH_REQUIRED') {
      primaryLabel = 'تسجيل الدخول';
      primaryIcon = Icons.login;
      primaryAction = () => context.go('/auth');
      primaryOutlined = false;
    } else if (details.session.isLive) {
      primaryLabel = isConnected
          ? 'أنت داخل الغرفة'
          : (isReconnecting
              ? 'إعادة الاتصال…'
              : (isConnecting
                  ? 'جارٍ الاتصال…'
                  : (_joiningLive
                      ? 'جارٍ تجهيز الدخول'
                      : (_refreshingToken
                          ? 'جارٍ تحديث الصلاحيات'
                          : 'انضم للبث'))));
      primaryIcon = Icons.headphones_outlined;
      primaryBusy = _joiningLive || _refreshingToken || isConnecting || isReconnecting;
      primaryAction = primaryBusy || isConnected
          ? null
          : _joinLiveRoom;
      primaryOutlined = false;
      primaryColor = const Color(0xFFFF3B30);

      if (details.access.canEndSession) {
        secondaryButtons.add(
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
        if (tokenCanPublish) {
          secondaryButtons.add(
            _actionButton(
              micEnabled ? 'كتم الميكروفون' : 'فتح الميكروفون',
              micEnabled ? Icons.mic_off_outlined : Icons.mic_none_outlined,
              _toggleMicrophone,
              outlined: true,
            ),
          );
        } else {
          secondaryButtons.add(
            _actionButton(
              _refreshingToken ? 'جارٍ التحديث…' : 'تفعيل الميكروفون',
              Icons.autorenew_rounded,
              _refreshingToken
                  ? null
                  : () => _refreshLivekitTokenAndReconnect(
                        enableMicrophoneAfter: true,
                        reason: 'manual_enable_mic',
                      ),
              outlined: true,
            ),
          );
        }
      }

      if (details.access.isRegistered && !details.access.canSpeak) {
        secondaryButtons.add(
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
    } else if (details.access.canStartSession) {
      primaryLabel = 'ابدأ البث';
      primaryIcon = Icons.play_circle_outline;
      primaryAction = () => _runRoomAction(
            action: 'start_live',
            successMessage: 'تم بدء البث الصوتي.',
          );
      primaryOutlined = false;
      primaryColor = const Color(0xFFFF3B30);
    } else if (details.access.isRegistered) {
      primaryLabel = 'إلغاء التسجيل';
      primaryIcon = Icons.event_busy_outlined;
      primaryAction = _leaveSession;
      primaryOutlined = true;
    } else if (details.access.canJoin) {
      primaryLabel = 'سجل الآن';
      primaryIcon = Icons.event_available_outlined;
      primaryAction = _registerForSession;
      primaryOutlined = false;
    }

    final busyIndicator = SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: primaryOutlined
            ? AppColors.appBarForeground(isDark)
            : Colors.white.withAlpha(230),
      ),
    );

    final primaryLeading =
        primaryBusy ? busyIndicator : Icon(primaryIcon, size: 20);

    return _sectionCard(
      isDark: isDark,
      title: 'الإجراءات',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showTokenNotice) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.subtleFill(isDark),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.autorenew_rounded,
                    color: AppColors.appBarForeground(isDark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      publishMismatch
                          ? 'تمت ترقيتك داخل الجلسة. جارٍ تحديث صلاحيات البث…'
                          : (revokeMismatch
                              ? 'تم تغيير دورك. جارٍ تحديث الاتصال…'
                              : 'جارٍ تحديث الاتصال…'),
                      style: TextStyle(
                        color: AppColors.textPrimary(isDark),
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (!_refreshingToken)
                    TextButton(
                      onPressed: () => _refreshLivekitTokenAndReconnect(
                        reason: 'manual_retry',
                      ),
                      child: const Text('إعادة المحاولة'),
                    )
                  else
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            height: 52,
            child: primaryOutlined
                ? OutlinedButton.icon(
                    onPressed: primaryAction,
                    icon: primaryLeading,
                    label: Text(primaryLabel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.appBarForeground(isDark),
                      side: BorderSide(color: AppColors.borderColor(isDark)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: primaryAction,
                    icon: primaryLeading,
                    label: Text(primaryLabel),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: primaryColor.withAlpha(140),
                      disabledForegroundColor: Colors.white.withAlpha(210),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
          ),
          if (secondaryButtons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: secondaryButtons,
            ),
          ],
        ],
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
    final activeSpeakerIds = _room?.activeSpeakers
            .map((participant) => participant.identity)
            .toSet() ??
        <String>{};
    final highlight = isDark ? AppColors.darkPrimary : AppColors.accent;

    return _sectionCard(
      isDark: isDark,
      title: 'المشاركون',
      child: Column(
        children: [
          if (details.participants.isNotEmpty) ...[
            SizedBox(
              height: 54,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final participant = details.participants[index];
                  final isActive = activeSpeakerIds.contains(participant.id);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive ? highlight : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: _avatar(isDark, participant.avatarUrl),
                      ),
                    ],
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemCount: details.participants.length > 10
                    ? 10
                    : details.participants.length,
              ),
            ),
            const SizedBox(height: 14),
          ],
          ...details.participants.map((participant) {
            final isActive = activeSpeakerIds.contains(participant.id);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.subtleFill(isDark),
                borderRadius: BorderRadius.circular(18),
                border: isActive
                    ? Border.all(color: highlight.withAlpha(200), width: 2)
                    : null,
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
                            if (isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: highlight.withAlpha(22),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: highlight.withAlpha(120),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PulsingDot(color: highlight, size: 7),
                                    const SizedBox(width: 6),
                                    Text(
                                      'يتحدث',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary(isDark),
                                      ),
                                    ),
                                  ],
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
                    const Icon(
                      Icons.pan_tool_alt_outlined,
                      color: AppColors.warning,
                      size: 18,
                    ),
                  if (_participantActions(
                          details.access, participant, currentUserId)
                      .isNotEmpty)
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
            );
          }),
        ],
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
        const {'speaker', 'moderator', 'co_host'}
            .contains(participant.roomRole)) {
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

  Widget _statusDot(Color color, {bool pulsing = false}) {
    return PulsingDot(
      color: color,
      size: 10,
      enabled: pulsing,
    );
  }

  Widget _heroAvatar(String? avatarUrl, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive ? Colors.white : Colors.white.withAlpha(90),
          width: isActive ? 2.5 : 1.5,
        ),
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white.withAlpha(28),
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null
            ? const Icon(Icons.person_outline, color: Colors.white)
            : null,
      ),
    );
  }

  Widget _heroAvatarStack(
    List<SessionParticipantModel> participants,
    Set<String> activeSpeakerIds,
    Color accent,
  ) {
    if (participants.isEmpty) {
      return const SizedBox.shrink();
    }

    const overlap = 18.0;
    final max = participants.length > 6 ? 6 : participants.length;
    final width = 40 + (max - 1) * overlap;

    return SizedBox(
      height: 40,
      width: width,
      child: Stack(
        children: [
          for (var i = 0; i < max; i++)
            Positioned(
              right: i * overlap,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(12),
                  border: Border.all(
                    color: activeSpeakerIds.contains(participants[i].id)
                        ? accent
                        : Colors.white.withAlpha(110),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withAlpha(28),
                  backgroundImage: participants[i].avatarUrl != null
                      ? NetworkImage(participants[i].avatarUrl!)
                      : null,
                  child: participants[i].avatarUrl == null
                      ? const Icon(Icons.person_outline,
                          color: Colors.white, size: 18)
                      : null,
                ),
              ),
            ),
          if (participants.length > max)
            Positioned(
              right: max * overlap,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white.withAlpha(28),
                child: Text(
                  '+${participants.length - max}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
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

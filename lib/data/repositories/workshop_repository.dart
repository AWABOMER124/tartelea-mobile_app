import '../../core/api/api_client.dart';
import '../../core/api/api_payload.dart';
import '../models/workshop_model.dart';

class WorkshopRepository {
  final ApiClient _api;

  WorkshopRepository(this._api);

  Future<List<WorkshopModel>> getWorkshops() async {
    final response = await _api.get('/workshops');

    final workshops = ApiPayload.unwrapList(response.data);
    return workshops
        .map((json) => WorkshopModel.fromJson(json))
        .toList();
  }
}

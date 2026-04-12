import 'package:hext/core/models/agenda_visita.dart';

abstract class AgendaRepo {
  List<AgendaVisita> get items;

  Future<void> load();

  List<AgendaVisita> itemsByDate(DateTime date);

  AgendaVisita? findById(String id);

  Future<void> addVisita(AgendaVisita visita);

  Future<void> updateVisita(AgendaVisita visita);

  Future<void> deleteVisita(String id);
}

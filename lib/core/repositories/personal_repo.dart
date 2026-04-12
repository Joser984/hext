import 'package:hext/core/models/auxiliar_domiciliario.dart';

abstract class PersonalRepo {
  List<AuxiliarDomiciliario> get items;

  Future<void> load();

  AuxiliarDomiciliario? findById(String id);

  Future<void> addAuxiliar(AuxiliarDomiciliario auxiliar);

  Future<void> updateAuxiliar(AuxiliarDomiciliario auxiliar);

  Future<void> deleteAuxiliar(String id);

  Future<void> toggleActivo(String id, bool activo);
}

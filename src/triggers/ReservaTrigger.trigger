/**
 * Created by guilhermereis on 01/02/21.
 */

trigger ReservaTrigger on Reserva__c (before insert, before update) {
    ReservaService reservaService = new ReservaService(Trigger.new, Trigger.old, Trigger.newMap, Trigger.oldMap);
    if (Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert)) {
        reservaService.deleteExistingReservas();
    }
}
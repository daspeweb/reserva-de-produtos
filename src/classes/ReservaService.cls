/**
 * Created by guilhermereis on 01/02/21.
 */

public with sharing class ReservaService {
    List<Reserva__c> reservaListNew;
    List<Reserva__c> reservaListOld;
    Map<Id, Reserva__c> reservaMapNew;
    Map<Id, Reserva__c> reservaMapOld;
    public ReservaService(List<Reserva__c> reservaListNew, List<Reserva__c> reservaListOld, Map<Id, Reserva__c> reservaMapNew, Map<Id, Reserva__c> reservaMapOld){
        this.reservaListNew = reservaListNew;
        this.reservaListOld = reservaListOld == null ? new List<Reserva__c>() : reservaListOld;
        this.reservaMapNew = reservaMapNew;
        this.reservaMapOld = reservaMapOld == null ? new Map<Id, Reserva__c>() : reservaMapOld;
    }

    public void deleteExistingReservas(){
        Set<Id> oppSet = new Set<Id>();
        for (Reserva__c reserva : this.reservaListNew) oppSet.add(reserva.Oportunidade__c);

        List<Reserva__c> reservaList = (List<Reserva__c>)DW_QueryFactory.get('Reserva__c')
                .setCondition(DW_QueryCondition.newInstance('Oportunidade__c', oppSet))
                .run();

        delete reservaList;
    }
}
/**
 * Created by guilhermereis on 25/01/21.
 */

public with sharing class ReservaEstoqueLWCController {
    @AuraEnabled
    public static String getOpportunityAndRelatedDataByOppIdAura(Id opportunityId){
        return JSON.serialize(getOpportunityAndRelatedDataByOppId(opportunityId));
    }

    @AuraEnabled
    public static String upsertReservaAura(List<Reserva__c> reservaList){
        return JSON.serialize(upsertReserva(reservaList));
    }

    @AuraEnabled
    public static String deleteAllReservaByOppIdAura(Id opportunityId){
        return JSON.serialize(deleteAllReservaByOppId(opportunityId));
    }

    public static ResponseHTTP getOpportunityAndRelatedDataByOppId(Id opportunityId){
        Opportunity opportunity = (Opportunity)DW_QueryFactory.get('Opportunity')
            .setCondition(DW_QueryCondition.newInstance('Id', '=', opportunityId))
            .with('OpportunityLineItems')
            .with('Reservas__r', 'Reserva__c')
            .withParent('Account')
            .withParent('FilialFaturamento__r')
            .run()
            .get(0);

        List<Estoque__c> estoqueList = new List<Estoque__c>();
        Set<Id> productSet = new Set<Id>();

        for (OpportunityLineItem opportunityLineItem : opportunity.OpportunityLineItems) productSet.add(opportunityLineItem.Product2Id);

        if (opportunity.FilialFaturamento__c != null && opportunity.OpportunityLineItems.size() > 0) {
            estoqueList = (List<Estoque__c>)DW_QueryFactory.get('Estoque__c')
                .setCondition(DW_QueryCondition.newInstance('Produto__c', productSet))
                .setCondition(DW_QueryCondition.newInstance('FilialFaturamento__c', '=', opportunity.FilialFaturamento__c))
                .run();
        }

        return ResponseHTTP.successObj(new Map<String, Object>{
                'opportunity' => opportunity,
                'estoqueList' => estoqueList
        });
    }

    public static ResponseHTTP upsertReserva(List<Reserva__c> reservaList){
        Savepoint savepoint = Database.setSavepoint();
        Opportunity opportunity = (Opportunity)DW_QueryFactory.get('Opportunity')
            .setCondition(DW_QueryCondition.newInstance('Id', '=', reservaList.get(0).Oportunidade__c))
            .with('OpportunityLineItems')
            .with('Reservas__r', 'Reserva__c')
            .withParent('Account')
            .run()
            .get(0);

        if (opportunity.FilialFaturamento__c == null) {
            return ResponseHTTP.errorObj(new List<String>{
                'Não existe nenhuma filial de faturamento selecionada.'
            });
        }
        List<Database.UpsertResult> reservaListUpsertResult = Database.upsert(reservaList, false);
        List<String> errorByLine = new List<String>();
        for (Database.UpsertResult upsertResult : reservaListUpsertResult){
            if (upsertResult.getErrors().size() > 0) {
                errorByLine.add(upsertResult.getErrors().get(0).getMessage());
            }else{
                errorByLine.add('');
            }
        }

        Boolean cancelDML = false;
        for (String error : errorByLine){
            if (error != '') cancelDML = true;
        }
        if (cancelDML) {
            Database.rollback(savepoint);
            return ResponseHTTP.errorObj(errorByLine);
        }

        return ResponseHTTP.successObj(new Map<String, Object>{
            'reservaList' => reservaList
        });
    }

    public static ResponseHTTP deleteAllReservaByOppId(Id opportunityId){
        Boolean cancelDML = false;
        Savepoint savepoint = Database.setSavepoint();
        List<Reserva__c> reservaList = (List<Reserva__c>)DW_QueryFactory.get('Reserva__c')
                .setCondition(DW_QueryCondition.newInstance('Oportunidade__c', '=', opportunityId))
                .run();

        List<Database.DeleteResult> reservaListDeleteResult = Database.delete(reservaList, false);
        List<String> errorByLine = new List<String>();
        for (Database.DeleteResult deleteResult : reservaListDeleteResult){
            if (deleteResult.getErrors().size() > 0) {
                errorByLine.add(deleteResult.getErrors().get(0).getMessage());
            }else{
                errorByLine.add('');
            }
        }

        for (String error : errorByLine){
            if (error != '') cancelDML = true;
        }

        if (cancelDML) {
            Database.rollback(savepoint);
            return ResponseHTTP.errorObj(errorByLine);
        }

        return ResponseHTTP.successObj(new Map<String, Object>());
    }
}
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

    public static ResponseHTTP getOpportunityAndRelatedDataByOppId(Id opportunityId){
        Opportunity opportunity = (Opportunity)DW_QueryFactory.get('Opportunity')
                .setCondition(DW_QueryCondition.newInstance('Id', '=', opportunityId))
                .with('OpportunityLineItems', 'OpportunityLineItem')
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
        Opportunity opportunity = (Opportunity)DW_QueryFactory.get('Opportunity')
                .setCondition(DW_QueryCondition.newInstance('Id', '=', reservaList.get(0).Oportunidade__c))
                .with('OpportunityLineItems', 'OpportunityLineItem')
                .run()
                .get(0);

        Savepoint savepoint = Database.setSavepoint();
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
            if (error != '') {
                cancelDML = true;
            }
        }
        if (cancelDML) {
            Database.rollback(savepoint);
            return ResponseHTTP.errorObj(errorByLine);
        }

        return ResponseHTTP.successObj(new Map<String, Object>{
            'reservaList' => reservaList
        });
    }
}
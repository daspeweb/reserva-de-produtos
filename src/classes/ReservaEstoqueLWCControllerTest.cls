/**
 * Created by guilhermereis on 26/01/21.
 */
@IsTest
public with sharing class ReservaEstoqueLWCControllerTest {
    @IsTest
    public static void upsertReserva(){
        TestFactory.activeStandardPricebook();
        User user = TestFactory.getAnyUser();
        Account account = TestFactory.createAccount();
        Opportunity opportunity = TestFactory.createOpportunity(account);
        FilialFaturamento__c filialFaturamento = TestFactory.createFilialFaturamento();
        opportunity.FilialFaturamento__c = filialFaturamento.Id;
        update opportunity;
        Product2 product = TestFactory.createProduct();
        Product2 product2 = TestFactory.createProduct();
        Estoque__c estoque = TestFactory.createEstoque(product, filialFaturamento);
        Estoque__c estoque2 = TestFactory.createEstoque(product2, filialFaturamento);

        Reserva__c reserva = new Reserva__c();
        reserva.Oportunidade__c = opportunity.Id;
        reserva.Estoque__c = estoque.Id;
        reserva.QuantidadeReservada__c = 10;
        reserva.Vendedor__c = user.Id;

        Reserva__c reserva2 = new Reserva__c();
        reserva2.Estoque__c = estoque2.Id;
        reserva2.QuantidadeReservada__c = 10;
        reserva2.Vendedor__c = user.Id;

        List<Reserva__c> reservaList = new List<Reserva__c>{reserva, reserva2};

        ResponseHTTP responseHTTP = ReservaEstoqueLWCController.upsertReserva(reservaList);

        System.assertEquals(true, responseHTTP.error);
        System.assertEquals(2, responseHTTP.errorList.size());
        System.assert(responseHTTP.errorList.get(0) == '');
        System.assert(responseHTTP.errorList.get(1) != '');

        reserva2.Oportunidade__c = opportunity.Id;
        reserva2.Id = null;
        reserva.Id = null;
        System.debug(LoggingLevel.INFO, '@@@reservaList: ' + reservaList);
        responseHTTP = ReservaEstoqueLWCController.upsertReserva(reservaList);
        System.debug(LoggingLevel.INFO, '@@@responseHTTP.errorList: ' + responseHTTP.errorList);
        System.assertEquals(true, responseHTTP.success);

        responseHTTP = ReservaEstoqueLWCController.deleteAllReservaByOppId(opportunity.Id);
        System.assertEquals(true, responseHTTP.success);

        List<Reserva__c> reservaListToAssert = (List<Reserva__c>)DW_QueryFactory.get('Reserva__c')
                .setCondition(DW_QueryCondition.newInstance('Oportunidade__c', '=', opportunity.Id))
                .run();

        System.assertEquals(0, reservaListToAssert.size());
    }

    @IsTest
    public static void getOpportunityAndRelatedDataByOppId(){
        TestFactory.activeStandardPricebook();
        Account account = TestFactory.createAccount();
        Opportunity opportunity = TestFactory.createOpportunity(account);
        Product2 product2 = TestFactory.createProduct();
        Product2 product2ToAssertQuery = TestFactory.createProduct();
        PricebookEntry pricebookEntry = TestFactory.createPricebookEntryStandard(product2);

        ResponseHTTP responseHTTP = ReservaEstoqueLWCController.getOpportunityAndRelatedDataByOppId(opportunity.Id);
        Map<String, Object> objectsByStringMap = (Map<String, Object>)responseHTTP.dataMap;
        List<Estoque__c> estoqueList = (List<Estoque__c>)objectsByStringMap.get('estoqueList');
        System.assertEquals(0, estoqueList.size());

        FilialFaturamento__c filialFaturamento = TestFactory.createFilialFaturamento();
        opportunity.FilialFaturamento__c = filialFaturamento.Id;
        update opportunity;

        TestFactory.createOpportunityLineItem(opportunity, pricebookEntry);
        TestFactory.createEstoque(product2, filialFaturamento);
        TestFactory.createEstoque(product2ToAssertQuery, filialFaturamento);

        responseHTTP = ReservaEstoqueLWCController.getOpportunityAndRelatedDataByOppId(opportunity.Id);
        objectsByStringMap = (Map<String, Object>)responseHTTP.dataMap;
        estoqueList = (List<Estoque__c>)objectsByStringMap.get('estoqueList');
        System.assertEquals(1, estoqueList.size());
    }
}
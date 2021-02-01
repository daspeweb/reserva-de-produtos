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
        Product2 product2 = TestFactory.createProduct();
        Estoque__c estoque = TestFactory.createEstoque(product2, filialFaturamento);

        Reserva__c reserva = new Reserva__c();
        reserva.Oportunidade__c = opportunity.Id;
        reserva.Estoque__c = estoque.Id;
        reserva.QuantidadeReservada__c = 10;
        reserva.Vendedor__c = user.Id;

        Reserva__c reserva2 = new Reserva__c();
//        reserva.Oportunidade__c = opportunity.Id;
        reserva2.Estoque__c = estoque.Id;
        reserva2.QuantidadeReservada__c = 10;
        reserva2.Vendedor__c = user.Id;

        List<Reserva__c> reservaList = new List<Reserva__c>{reserva, reserva2};

        ResponseHTTP responseHTTP = ReservaEstoqueLWCController.upsertReserva(reservaList);
        System.assertEquals(true, responseHTTP.error);
        System.assertEquals(2, responseHTTP.errorList.size());
        System.assert(responseHTTP.errorList.get(0) == '');
        System.assert(responseHTTP.errorList.get(0) != '');

        reserva.Oportunidade__c = opportunity.Id;
        update reserva;

        ResponseHTTP responseHTTP = ReservaEstoqueLWCController.upsertReserva(reservaList);
        System.assertEquals(0, responseHTTP.success);
        System.assert(responseHTTP.errorList.get(0) == '');
        System.assert(responseHTTP.errorList.get(0) == '');

    }

    @IsTest
    public static void getOpportunityAndRelatedDataByOppId(){
        TestFactory.activeStandardPricebook();
        Account account = TestFactory.createAccount();
        Opportunity opportunity = TestFactory.createOpportunity(account);
        Product2 product2 = TestFactory.createProduct();
        Product2 product2ToAssertQuery = TestFactory.createProduct();
        PricebookEntry pricebookEntry = TestFactory.createPricebookEntryStandard(product2);

        //Order order = TestFactory.createOrder(account, opportunity, Test.getStandardPricebookId());
        //OrderItem orderItem = TestFactory.createOrderItem(order, opportunityLineItem);

        ResponseHTTP responseHTTP = ReservaEstoqueLWCController.getOpportunityAndRelatedDataByOppId(opportunity.Id);
        System.assertEquals(true, responseHTTP.error);
        System.assertEquals('Não existe nenhuma filial de faturamento selecionada.', responseHTTP.errorList.get(0));

        FilialFaturamento__c filialFaturamento = TestFactory.createFilialFaturamento();
        opportunity.FilialFaturamento__c = filialFaturamento.Id;
        update opportunity;

        responseHTTP = ReservaEstoqueLWCController.getOpportunityAndRelatedDataByOppId(opportunity.Id);
        System.assertEquals(true, responseHTTP.error);
        System.assertEquals('Não existe nenhum item na oportunidade.', responseHTTP.errorList.get(0));

        TestFactory.createOpportunityLineItem(opportunity, pricebookEntry);
        responseHTTP = ReservaEstoqueLWCController.getOpportunityAndRelatedDataByOppId(opportunity.Id);
        System.assertEquals(true, responseHTTP.success);

        TestFactory.createEstoque(product2, filialFaturamento);
        TestFactory.createEstoque(product2ToAssertQuery, filialFaturamento);
        responseHTTP = ReservaEstoqueLWCController.getOpportunityAndRelatedDataByOppId(opportunity.Id);
        Map<String, Object> objectsByStringMap = (Map<String, Object>)responseHTTP.dataMap;
        List<Estoque__c> estoqueList = (List<Estoque__c>)objectsByStringMap.get('estoqueList');
        System.assertEquals(1, estoqueList.size());
    }
}
/**
 * Created by guilhermereis on 01/02/21.
 */

@IsTest
public with sharing class ReservaTriggerTest {
    @IsTest
    public static void deleteExistingReservas(){
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
        reserva2.Oportunidade__c = opportunity.Id;
        reserva2.Estoque__c = estoque2.Id;
        reserva2.QuantidadeReservada__c = 10;
        reserva2.Vendedor__c = user.Id;

        insert reserva;
        insert reserva2;

        List<Reserva__c> reservaListToAssert = (List<Reserva__c>)DW_QueryFactory.get('Reserva__c')
                .setCondition(DW_QueryCondition.newInstance('Oportunidade__c', '=', opportunity.Id))
                .run();

        System.assertEquals(1, reservaListToAssert.size());

        Reserva__c reserva3 = new Reserva__c();
        reserva3.Oportunidade__c = opportunity.Id;
        reserva3.Estoque__c = estoque.Id;
        reserva3.QuantidadeReservada__c = 10;
        reserva3.Vendedor__c = user.Id;

        Reserva__c reserva4 = new Reserva__c();
        reserva4.Oportunidade__c = opportunity.Id;
        reserva4.Estoque__c = estoque2.Id;
        reserva4.QuantidadeReservada__c = 10;
        reserva4.Vendedor__c = user.Id;

        insert new List<Reserva__c>{reserva3, reserva4};

        reservaListToAssert = (List<Reserva__c>)DW_QueryFactory.get('Reserva__c')
                .setCondition(DW_QueryCondition.newInstance('Oportunidade__c', '=', opportunity.Id))
                .run();

        System.assertEquals(2, reservaListToAssert.size());
    }
}
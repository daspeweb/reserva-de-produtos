/**
 * Created by guilhermereis on 25/01/21.
 */

import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpportunityAndRelatedDataByOppIdAura from '@salesforce/apex/ReservaEstoqueLWCController.getOpportunityAndRelatedDataByOppIdAura';
import upsertReservaAura from '@salesforce/apex/ReservaEstoqueLWCController.upsertReservaAura';
import deleteAllReservaByOppIdAura from '@salesforce/apex/ReservaEstoqueLWCController.deleteAllReservaByOppIdAura';

export default class ReservaEstoqueLWC extends LightningElement {
    @api recordId;
    @api opportunity = {
        FilialFaturamento__r : {Name: 'Não definido'},
        OpportunityLineItems: {records: []}
    }
    draftValues = []
    errors = []
    hasRendered = false

    columns = [
        {
            label: 'Produto',
            fieldName: 'Product2IdLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank'
            }
        },
        { label: 'Quantidade', fieldName: 'Quantity', editable: false },
        { label: 'Quantidade disponível', fieldName: 'Estoque__QuantidadeDisponivel__c', editable: false },
        { label: 'Quantidade já reservada (total)', fieldName: 'QuantidadeAReservadaPorTodasOpps', type: 'number', editable: false },
        { label: 'Quantidade a ser reservada', fieldName: 'QuantidadeAReservada', type: 'number', editable: true }
    ]

    async renderedCallback() {
        if (this.hasRendered) return
        this.hasRendered = true
        this.getOpportunityAndRelatedData()
    }

    deleteAllReserva(){
        deleteAllReservaByOppIdAura({opportunityId: this.recordId})
        .then(result => {
            result = JSON.parse(result)
            console.log('@@@@@result: ', result)
            if (result.error){
                this.handleError(result.errorList)
            }else{
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Tudo certo!',
                    message: 'Reservas canceladas com sucesso',
                    variant: 'success',
                }));
                this.getOpportunityAndRelatedData()
            }
        })
        .catch(error => {
            this.handleError(['Erro desconhecido'])
            console.error(error)
        });
    }

    getOpportunityAndRelatedData(){
        getOpportunityAndRelatedDataByOppIdAura({opportunityId: this.recordId})
            .then(result => {
                result = JSON.parse(result)
                console.log('@@@@@result: ', result)
                if (result.error){
                    this.handleError(result.errorList)
                    this.dispatchEvent(new CustomEvent('close'));
                }else{
                    this.opportunity = result.dataMap.opportunity;
                    if (this.opportunity.FilialFaturamento__r === undefined){
                        this.opportunity.FilialFaturamento__r = {Name: 'Não definido'}
                    }
                    this.opportunity.OpportunityLineItems.records = this.opportunity.OpportunityLineItems.records.map(opportunityLineItem => {
                        let estoque = result.dataMap.estoqueList.find(
                            estoque => opportunityLineItem.Product2Id === estoque.Produto__c
                        )

                        opportunityLineItem.Estoque = estoque ?  estoque : {}
                        opportunityLineItem.Estoque__QuantidadeDisponivel__c = estoque ? estoque.QuantidadeDisponivel__c : 0

                        opportunityLineItem.QuantidadeAReservadaPorTodasOpps = estoque ? estoque.QuantidadeReservada__c : 0

                        opportunityLineItem.QuantidadeAReservada = opportunityLineItem.Quantity > opportunityLineItem.Estoque__QuantidadeDisponivel__c
                            ? opportunityLineItem.Estoque__QuantidadeDisponivel__c
                            : opportunityLineItem.Quantity

                        opportunityLineItem.Product2IdLink = '/'+opportunityLineItem.Product2Id
                        return opportunityLineItem
                    })
                    this.draftValues = []
                    this.opportunity.OpportunityLineItems.records.forEach(oli => {
                        this.draftValues.push({
                            Id: oli.Id,
                            QuantidadeAReservada: oli.QuantidadeAReservada
                        })
                    })
                    console.log('@@@@@this.opportunity.OpportunityLineItems: ', this.opportunity.OpportunityLineItems)
                }
            })
            .catch(error => {
                this.handleError(['Erro desconhecido'])
                console.error(error)
            });
    }

    reserveStock(event){
        let reservaSojbArr = this.opportunity.OpportunityLineItems.records.map(opportunityLineItem => {
            let draft = event.detail.draftValues.find(draft => draft.Id === opportunityLineItem.Id)
            console.log('@@@@draft: ', draft)
            return {
                Oportunidade__c: opportunityLineItem.OpportunityId,
                Estoque__c: opportunityLineItem.Estoque ? opportunityLineItem.Estoque.Id : '',
                Produto__c: opportunityLineItem.Product2Id,
                FilialFaturamento__c: this.opportunity.FilialFaturamento__c,
                QuantidadeReservada__c: draft ? draft.QuantidadeAReservada : 0
            }
        })

        upsertReservaAura({reservaList: reservaSojbArr})
            .then(result => {
                result = JSON.parse(result)
                console.log('@@@@result: ', result)
                if (result.error){
                    this.errors = {rows: {}, table: {}}
                    this.opportunity.OpportunityLineItems.records.forEach((oli, index) => {
                        if (result.errorList[index] === '') return
                        this.errors.rows[oli.Id] = {
                            title: 'Ops',
                            messages: [result.errorList[index] || 'Algo deu errado'],
                            fieldNames: ['QuantidadeAReservada']
                        }
                    })
                    this.errors.table = {
                        title: 'Ops.',
                        messages: [result.errorList[0] || 'Algo deu errado. Erro desconhecido.']
                    }
                }else{
                    this.dispatchEvent(new CustomEvent('close'));
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Tudo certo!',
                        message: 'Reservas realizadas com sucesso',
                        variant: 'success',
                    }));
                    this.getOpportunityAndRelatedData()
                }
            })
            .catch(error => {
                this.handleError(['Erro desconhecido'])
                console.error(error)
            });
    }

    handleError(errAr){
        errAr.forEach(error => {
            if (error === '') return
            this.dispatchEvent(new ShowToastEvent({
                title: 'Ops',
                message: error,
                variant: 'error',
            }));
        })
    }

}
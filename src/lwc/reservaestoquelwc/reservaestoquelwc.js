/**
 * Created by guilhermereis on 25/01/21.
 */

import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpportunityAndRelatedDataByOppIdAura from '@salesforce/apex/ReservaEstoqueLWCController.getOpportunityAndRelatedDataByOppIdAura';
import upsertReservaAura from '@salesforce/apex/ReservaEstoqueLWCController.upsertReservaAura';

export default class ReservaEstoqueLWC extends LightningElement {
    @api recordId;
    @api opportunity = {OpportunityLineItems: {records: []}}
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
        { label: 'Quantidade a ser reservada', fieldName: 'QuantidadeReservada', type: 'number', editable: true }
    ]

    reserveStock(event){
        let reservaSojbArr = this.opportunity.OpportunityLineItems.records.map(opportunityLineItem => {
            let draft = event.detail.draftValues.find(draft => draft.Id === opportunityLineItem.Id)
            console.log('@@@@draft: ', draft)
            return {
                Oportunidade__c: opportunityLineItem.OpportunityId,
                Estoque__c: opportunityLineItem.Estoque ? opportunityLineItem.Estoque.Id : '',
                Produto__c: opportunityLineItem.Product2Id,
                FilialFaturamento__c: this.opportunity.FilialFaturamento__c,
                QuantidadeReservada__c: draft ? draft.QuantidadeReservada : 0
            }
        })

        upsertReservaAura({reservaList: reservaSojbArr})
            .then(result => {
                result = JSON.parse(result)
                console.log('@@@@result: ', result)
                if (result.error){
                    this.errors = {rows: {}}

                    this.opportunity.OpportunityLineItems.records.forEach((oli, index) => {
                        if (result.errorList[index] === '') return
                        this.errors.rows[oli.Id] = {
                            title: 'Ops',
                            messages: [result.errorList[index] || 'Algo deu errado'],
                            fieldNames: ['QuantidadeReservada']
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
                }
            })
            .catch(error => {
                this.handleError(['Erro desconhecido'])
                console.error(error)
            });
    }

    async renderedCallback() {
        if (this.hasRendered) return
        this.hasRendered = true

        getOpportunityAndRelatedDataByOppIdAura({opportunityId: this.recordId})
            .then(result => {
                result = JSON.parse(result)
                console.log('@@@@@result: ', result)
                if (result.error){
                    this.handleError(result.errorList)
                    this.dispatchEvent(new CustomEvent('close'));
                }else{
                    this.opportunity = result.dataMap.opportunity;
                    this.opportunity.OpportunityLineItems.records = this.opportunity.OpportunityLineItems.records.map(opportunityLineItem => {
                        let estoque = result.dataMap.estoqueList.find(
                            estoque => opportunityLineItem.Product2Id === estoque.Produto__c
                        )

                        opportunityLineItem.Estoque = estoque ?  estoque : {}
                        opportunityLineItem.Estoque__QuantidadeDisponivel__c = estoque ? estoque.QuantidadeDisponivel__c : 0

                        opportunityLineItem.QuantidadeReservada = opportunityLineItem.Quantity > opportunityLineItem.Estoque__QuantidadeDisponivel__c
                            ? opportunityLineItem.Estoque__QuantidadeDisponivel__c
                            : opportunityLineItem.Quantity

                        opportunityLineItem.Product2IdLink = '/'+opportunityLineItem.Product2Id
                        return opportunityLineItem
                    })
                    this.draftValues = []
                    this.opportunity.OpportunityLineItems.records.forEach(oli => {
                        this.draftValues.push({
                            Id: oli.Id,
                            QuantidadeReservada: oli.QuantidadeReservada
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

    handleError(errAr){
        errAr.forEach(error => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Ops',
                message: error,
                variant: 'error',
            }));
        })
    }

}
/**
 * Created by guilhermereis on 01/02/21.
 */

({
    closeQA : function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})
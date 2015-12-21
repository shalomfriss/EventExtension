//
//  EventExtension.swift
//  Aud
//
//  Created by Friss, Shalom on 12/16/15.
//  Copyright © 2015 Friss, Shalom (EHQ). All rights reserved.
//
// Credit to https://medium.com/@ttikitu/swift-extensions-can-add-stored-properties-92db66bce6cd#.2q7j8ag73
// and https://github.com/StephenHaney/Swift-Custom-Events
//

import Foundation

/**
    Utility functions based on https://medium.com/@ttikitu/swift-extensions-can-add-stored-properties-92db66bce6cd#.2q7j8ag73
    for storing variables inside of extensions
*/
func associatedObject<ValueType: AnyObject>(
    base: AnyObject,
    key: UnsafePointer<UInt8>,
    initialiser: () -> ValueType)
    -> ValueType {
        if let associated = objc_getAssociatedObject(base, key)
            as? ValueType { return associated }
        let associated = initialiser()
        objc_setAssociatedObject(base, key, associated,
            .OBJC_ASSOCIATION_RETAIN)
        return associated
}

func associateObject<ValueType: AnyObject>(
    base: AnyObject,
    key: UnsafePointer<UInt8>,
    value: ValueType) {
        objc_setAssociatedObject(base, key, value,
            .OBJC_ASSOCIATION_RETAIN)
}

/**
    A wrapper class for the Dictionary since it cannot be intialized in the associatedObject function
*/
class Listeners { // Every Miller should have a Cat
    var items = Dictionary<String, NSMutableArray>()
}

//A reference key
private var _lKey: UInt8 = 0

/**
    The NSObject extension
*/
extension NSObject
{
    
    /*
        The Listeners get/set
    */
    var listeners : Listeners{
        get
        {
            return associatedObject(self, key: &_lKey, initialiser: { return Listeners() } )
        }
        set
        {
            associateObject(self, key: &_lKey, value: newValue)
        }
    }
    
    
    // Create a new event listener, not expecting information from the trigger
    // + eventName: Matching trigger eventNames will cause this listener to fire
    // + action: The block of code you want executed when the event triggers
    func addListener(eventName:String, action:(()->()), listenerId:String? = nil) {
        let newListener = EventListenerAction(callback: action);
        if((listenerId) != nil)
        {
            newListener.listenerId = listenerId!
        }
        
        _addListener(eventName, newEventListener: newListener);
    }
    
    // Create a new event listener, expecting information from the trigger
    // + eventName: Matching trigger eventNames will cause this listener to fire
    // + action: The block of code you want executed when the event triggers
    func addListener(eventName:String, action:((Any?)->()), listenerId:String? = nil) {
        let newListener = EventListenerAction(callback: action);
        if((listenerId) != nil)
        {
            newListener.listenerId = listenerId!
        }
        _addListener(eventName, newEventListener: newListener);
    }
    
    /**
        Add a listener internally
        + eventName: Matching trigger eventNames will cause this listener to fire
        + newEventListener:EventListenerAction The Event Listener Action object
    */
    internal func _addListener(eventName:String, newEventListener:EventListenerAction) {
        if let listenerArray = self.listeners.items[eventName] {
            // action array exists for this event, add new action to it
            listenerArray.addObject(newEventListener);
        }
        else {
            // no listeners created for this event yet, create a new array
            self.listeners.items[eventName] = [newEventListener] as NSMutableArray;
        }
    }
    
    /**
        Remove a listener with the given id
        + eventName:String The event associated with this listener
        + listenerId:String The listener id
    */
    func removeListener(eventName:String, listenerId:String)
    {
        if let actionObjects = self.listeners.items[eventName]
        {
            for actionObject in actionObjects
            {
                var act = actionObject as! EventListenerAction
                if(act.listenerId == listenerId)
                {
                    actionObjects.removeObject(act)
                    return;
                }
            }
        }
        
    }
    
    
    // Removes all listeners by default, or specific listeners through paramters
    // + eventName: If an event name is passed, only listeners for that event will be removed
    func removeListeners(eventNameToRemoveOrNil:String?)
    {
        if let eventNameToRemove = eventNameToRemoveOrNil {
            // remove listeners for a specific event
            
            if let actionArray = self.listeners.items[eventNameToRemove] {
                // actions for this event exist
                actionArray.removeAllObjects();
            }
        }
        else {
            // no specific parameters - remove all listeners on this object
            self.listeners.items.removeAll(keepCapacity: false);
        }
    }
    
    // Triggers an event
    // + eventName: Matching listener eventNames will fire when this is called
    // + information: pass values to your listeners
    func trigger(eventName:String, information:Any? = nil) {
        if let actionObjects = self.listeners.items[eventName] {
            for actionObject in actionObjects {
                if let actionToPerform = actionObject as? EventListenerAction {
                    if let methodToCall = actionToPerform.actionExpectsInfo {
                        methodToCall(information);
                    }
                    else if let methodToCall = actionToPerform.action {
                        methodToCall();
                    }
                }
            }
        }
    }
}



// Class to hold actions to live in NSMutableArray
class EventListenerAction {
    let action:(() -> ())?;
    let actionExpectsInfo:((Any?) -> ())?;
    var listenerId:String = ""
    
    required init()
    {
        action = nil;
        actionExpectsInfo = nil;
    }
    
    init(callback:(() -> ())) {
        self.action = callback;
        self.actionExpectsInfo = nil;
    }
    
    init(callback:((Any?) -> ())) {
        self.actionExpectsInfo = callback;
        self.action = nil;
    }
}

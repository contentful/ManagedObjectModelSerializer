//
//  EntitySerializer.swift
//  ManagedObjectModelSerializer
//
//  Created by Boris Bügling on 31/10/14.
//  Copyright (c) 2014 Boris Bügling. All rights reserved.
//

import CoreData

func attributeTypeToString(type : NSAttributeType) -> String {
    switch(type) {
    case .BinaryDataAttributeType:
        return "Binary"
    case .BooleanAttributeType:
        return "Boolean"
    case .DateAttributeType:
        return "Date"
    case .DecimalAttributeType:
        return "Decimal"
    case .DoubleAttributeType:
        return "Double"
    case .FloatAttributeType:
        return "Float"
    case .Integer16AttributeType:
        return "Integer 16"
    case .Integer32AttributeType:
        return "Integer 32"
    case .Integer64AttributeType:
        return "Integer 64"
    case .StringAttributeType:
        return "String"
    case .TransformableAttributeType:
        return "Transformable"
    default:
        return ""
    }
}

class EntitySerializer: NSObject {
    let entity : NSEntityDescription

    init(entity : NSEntityDescription) {
        self.entity = entity
    }

    func attributes() -> [XMLNode] {
        let attributes = ((entity.attributesByName as NSDictionary).allValues as! [NSAttributeDescription]).sorted({ (attr1 : NSAttributeDescription, attr2 : NSAttributeDescription) -> Bool in
            return attr1.name < attr2.name
        })
        return attributes.map({
            let attribute = $0 as NSAttributeDescription
            var result = </"attribute" | ["name": attribute.name] | ["optional": "YES"] | ["attributeType": attributeTypeToString(attribute.attributeType)]

            if let defaultValue = attribute.defaultValue as? NSObject {
                var value = defaultValue.description

                switch(attribute.attributeType) {
                case .DoubleAttributeType, .FloatAttributeType, .DecimalAttributeType:
                    if !contains(value, ".") {
                        value += ".0"
                    }
                    break

                default:
                    break
                }

                result = result | ["defaultValueString": value]
            }

            result = result | ["syncable": "YES"]
            return result
        })
    }

    // TODO: Support delete rules
    func relationships() -> [XMLNode] {
        let relationships = ((entity.relationshipsByName as NSDictionary).allValues as! [NSRelationshipDescription]).sorted { (rel1 : NSRelationshipDescription, rel2 : NSRelationshipDescription) -> Bool in
            return rel1.name < rel2.name
        }
        return relationships.map({
            let relationship = $0 as NSRelationshipDescription
            var result = </"relationship" | ["name": relationship.name] | ["optional": "YES"]

            if relationship.maxCount > 0 {
                result = result | ["maxCount": String(relationship.maxCount)]
            }

            if relationship.minCount > 0 {
                result = result | ["maxCount": String(relationship.minCount)]
            }

            if relationship.toMany {
                result = result | ["toMany": "YES"]
            }

            result = result | ["deletionRule": "Nullify"]

            if relationship.ordered {
                result = result | ["ordered": "YES"]
            }

            if relationship.destinationEntity != nil {
                let destination = relationship.destinationEntity!.name! as String
                result = result | ["destinationEntity": destination]
            }

            if relationship.inverseRelationship != nil {
                let inverseRelationship = relationship.inverseRelationship!
                let inverse = inverseRelationship.name as String
                result = result | ["inverseName": inverse]

                /*if inverseRelationship.destinationEntity != nil {
                    let destination = inverseRelationship.destinationEntity!.name! as String
                    result = result | ["inverseEntity": destination]
                }*/

                if relationship.destinationEntity != nil {
                    let destination = relationship.destinationEntity!.name! as String
                    result = result | ["inverseEntity": destination]
                }
            }

            result = result | ["syncable": "YES"]
            return result
        })
    }

    func generate() -> XMLElement {
        return </"entity" | ["name": entity.name!] | ["representedClassName": entity.name!] | ["syncable": "YES"] | attributes() | relationships()
    }
}

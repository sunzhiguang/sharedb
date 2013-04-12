# This contains the master OT functions for the database. They look like ot-types style operational transform
# functions, but they're a bit different. These functions understand versions and can deal with out of bound
# create & delete operations.

otTypes = require 'ot-types'

exports.normalize = (opData) ->
  if opData.create
    # We should store the full URI of the type, not just its short name
    opData.create.type = otTypes[opData.create.type].uri

# This is the super apply function that takes in snapshot data (including the type) and edits it in-place.
# Returns an error string or null for success.
exports.apply = (data, opData) ->
  return 'Missing data' unless typeof opData is 'object'
  return 'Missing op' unless typeof (opData.op or opData.create) is 'object' or opData.del is true

  if !data.type
    # The document doesn't exist, although it might have once existed. Here we will only allow creates.
    create = opData.create
    return 'Document does not exist' unless typeof create is 'object'

    type = otTypes[create.type]
    return "Type not found" unless type

    snapshot = type.create create.data

    data.data = snapshot
    data.type = type.uri
    data.v++

  else if opData.del
    delete data.data
    delete data.type
    data.v++

  else
    # Apply the op data
    op = opData.op
    return 'Missing op' unless typeof op is 'object'
    type = otTypes[data.type]
    return 'Type not found' unless type

    try
      data.data = type.apply data.data, op
    catch e
      console.log e.stack
      return e.message
    data.v++

  return

exports.transform = (type, opData, appliedOpData) ->
  return 'Document was deleted' if appliedOpData.del
    
  return 'Document created remotely' if appliedOpData.create # type will be null / undefined in this case.

  return 'Document does not exist' unless type

  if typeof type is 'string'
    type = otTypes[type]
    return "Type not found" unless type

  opData.op = type.transform opData.op, appliedOpData.op, 'left'
  opData.v++

  return



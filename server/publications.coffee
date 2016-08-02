# Meteor.publish 'top_10', (selected_tags)->
#     # user_ranking = []
#     # Authors.find({
#     #     authored_list: $in: [tag]
#     # })
    
#     Authors.find({
#         authored_list: $all: selected_tags
#     })
    


Docs.allow
    insert: (userId, doc)-> userId
    update: (userId, doc)-> doc.authorId is Meteor.userId()
    remove: (userId, doc)-> doc.authorId is Meteor.userId()


Meteor.publish 'docs', (selected_tags)->
    Counts.publish(this, 'doc_counter', Docs.find(), { noReady: true })

    match = {}
    if selected_tags.length > 0 then match.tags = $all: selected_tags

    Docs.find match,
        limit: 10

Meteor.publish 'doc', (id)-> Docs.find id

Meteor.publish 'people', -> Meteor.users.find {}

Meteor.publish 'person', (id)-> Meteor.users.find id

# Meteor.publish 'usernames', (selected_tags)->
#     self = @

#     match = {}
#     if selected_tags.length > 0 then match.keyword_array = $all: selected_tags

#     cloud = Docs.aggregate [
#         { $match: match }
#         { $project: username: 1 }
#         { $group: _id: '$username', count: $sum: 1 }
#         { $match: _id: $nin: selected_usernames }
#         { $sort: count: -1, _id: 1 }
#         { $limit: 10 }
#         { $project: _id: 0, text: '$_id', count: 1 }
#         ]

#     cloud.forEach (username) ->
#         self.added 'usernames', Random.id(),
#             text: username.text
#             count: username.count
#     self.ready()


Meteor.publish 'tags', (selected_tags)->
    self = @
    # me = Meteor.users.findOne @userId
    # console.log me
    match = {}
    if selected_tags.length > 0 then match.tags = $all: selected_tags

    cloud = Docs.aggregate [
        { $match: match }
        { $project: tags: 1 }
        { $unwind: '$tags' }
        { $group: _id: '$tags', count: $sum: 1 }
        { $match: _id: $nin: selected_tags }
        { $sort: count: -1, _id: 1 }
        { $limit: 20 }
        { $project: _id: 0, text: '$_id', count: 1 }
        ]

    cloud.forEach (tag, i) ->
        self.added 'tags', Random.id(),
            text: tag.text
            count: tag.count
            index: i

    self.ready()
    
    
Meteor.publish 'people_tags', (selected_tags)->
    self = @
    match = {}
    if selected_tags?.length > 0 then match.tags = $all: selected_tags
    match._id = $ne: @userId

    tagCloud = Meteor.users.aggregate [
        { $match: match }
        { $project: "tags": 1 }
        { $unwind: "$tags" }
        { $group: _id: "$tags", count: $sum: 1 }
        { $match: _id: $nin: selected_tags }
        { $sort: count: -1, _id: 1 }
        { $limit: 50 }
        { $project: _id: 0, name: '$_id', count: 1 }
        ]

    tagCloud.forEach (tag, i) ->
        self.added 'people_tags', Random.id(),
            name: tag.name
            count: tag.count
            index: i

    self.ready()


# Meteor.publish 'me_as_author', ->
#     me = Meteor.users.findOne @userId
#     Authors.find username: me.profile.name
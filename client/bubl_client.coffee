@selected_tags = new ReactiveArray []
@selected_usernames = new ReactiveArray []


# Meteor.loginWithInstagram (err) ->
#     if err
#         console.log 'login failed', err
#     else
#         console.log 'login success', Meteor.user()
#     return

Template.home.onCreated ->
    Meteor.subscribe 'people'
    # @autorun -> Meteor.subscribe('usernames', selected_tags.array())
    @autorun -> Meteor.subscribe 'tags', selected_tags.array() 
    @autorun -> Meteor.subscribe 'docs', selected_tags.array()

Template.view.onCreated ->
    Meteor.subscribe 'person', @authorId

Template.nav.helpers
    doc_counter: -> Counts.get('doc_counter')
    user_counter: -> Meteor.users.find().count()


Template.nav.events
    'click .sync_tweets': -> Meteor.call 'sync_tweets', Meteor.user().profile.name, ->
   
    'click .sync_instagram': -> Meteor.call 'sync_instagram', ->
   
    'click .clear_my_docs': -> Meteor.call 'clear_my_docs', ->
        Meteor.setTimeout (->
            selected_usernames.clear()
            selected_tags.clear()
            ), 1000



Template.check_in.events
    'keyup #check_in': (e,t)->
        if e.which is 13
            location = $('#check_in').val()
            console.log location
            Meteor.call 'check_in', location, ->
                console.log "checked into #{location}"





Template.home.helpers
    cloud_tag_class: ->
        buttonClass = switch
            when @index <= 5 then 'big'
            when @index <= 10 then 'large'
            when @index <= 15 then ''
            when @index <= 20 then 'small'
            when @index <= 50 then 'tiny'
        return buttonClass


    global_tags: -> Tags.find()
    selected_tags: -> selected_tags.list()

    global_usernames: -> Usernames.find()
    selected_usernames: -> selected_usernames.list()

    user: -> Meteor.user()
    docs: -> Docs.find()

    viewMyTweetsClass: -> if Meteor.user().profile.name in selected_usernames.array() then 'primary' else ''
    hasReceivedTweets: -> Meteor.user().hasReceivedTweets


    matchedUsersList:->
        userMatches = []
        users = Authors.find({ _id: $ne: Meteor.user().username }).fetch()
        for user in users
            tagIntersection = _.intersection(user.authored_list, Meteor.user().authored_list)
            userMatches.push
                matched_user_id: user._id
                matchedUser: user.username
                tagIntersection: tagIntersection
                length: tagIntersection.length
        sortedList = _.sortBy(userMatches, 'length').reverse()
        clipped_list = []
        for item in sortedList
            # console.log item
            clipped_list.push
                matchedUser: item.matchedUser
                tagIntersection: item.tagIntersection.slice(0,5)
                length: item.length

        # console.log(item) for item in clipped_list
        return clipped_list
        # return sortedList



Template.home.events
    'click .select_username': -> selected_usernames.push @text
    
    'click .unselect_username': -> selected_usernames.remove @valueOf()
    
    'click #clear_usernames': -> selected_usernames.clear()

    'click .select_tag': -> 
        Session.set('tag_selection', @text)
        selected_tags.push @text
    
    'click .unselect_tag': -> selected_tags.remove @valueOf()
    
    'click #clear_tags': -> selected_tags.clear()


    'click .view_my_tweets': -> if Meteor.user().profile.name in selected_usernames.array() then selected_usernames.remove Meteor.user().profile.name else selected_usernames.push Meteor.user().profile.name

    'click .tweetViewAuthorButton': -> if @username in selected_usernames.array() then selected_usernames.remove @username else selected_usernames.push @username

    'click .authorFilterButton': (event)->
        if event.target.innerHTML in selected_usernames.array() then selected_usernames.remove event.target.innerHTML else selected_usernames.push event.target.innerHTML

    # 'keyup .authorName': (e,t)->
    #     if e.which is 13
    #         username = $('.authorName').val()
    #         console.log username
    #         Meteor.call 'get_tweets', username, ->
    #             Meteor.setTimeout (->
    #             selected_usernames.push username
    #             ), 1000


Template.view.helpers
    doc_tag_class: -> if @valueOf() in selected_tags.array() then 'grey' else ''
    authorButtonClass: -> if @username in selected_usernames.array() then 'active' else ''
    is_author: -> @authorId is Meteor.userId()
    when: -> moment(@timestamp).fromNow()
    tweet_created_when: -> moment(@tweet_created_at).format("dddd, MMMM Do YYYY")

Template.view.events
    'click .delete_tweet': -> Docs.remove @_id
    'click .doc_tag': -> if @valueOf() in selected_tags.array() then selected_tags.remove @valueOf() else selected_tags.push @valueOf()


Template.my_tags.helpers
    my_tags: -> 
        me = Authors.findOne username: Meteor.user().profile.name
        # console.log me?.authored_cloud
        me?.authored_list
        
    my_tag_class: -> if @valueOf() in selected_tags.array() then 'primary' else ''

    

Template.my_tags.events
    # 'click .my_tag': -> Session.set('tag_selection', @valueOd())
    'click .my_tag': -> if @valueOf() in selected_tags.array() then selected_tags.remove @valueOf() else selected_tags.push @valueOf()



Template.my_tags.onCreated ->
    @autorun -> Meteor.subscribe('me_as_author')


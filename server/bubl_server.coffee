

Meteor.methods
    sync_tweets: (username)->
        twitterConf = ServiceConfiguration.configurations.findOne(service: 'twitter')
        twitter = Meteor.user().services.twitter

        Twit = new TwitMaker(
            consumer_key: twitterConf.consumerKey
            consumer_secret: twitterConf.secret
            access_token: twitter.accessToken
            access_token_secret: twitter.accessTokenSecret
            app_only_auth:true)

        Twit.get 'statuses/user_timeline', {
            screen_name: username
            count: 200
            include_rts: true
            exclude_replies: false
        }, Meteor.bindEnvironment(((err, data, response) ->
            for tweet in data
                # console.log tweet
                found_tweet = Docs.findOne(tweet.id_str)
                if found_tweet
                    console.log 'found duplicate ', tweet.id_str
                    continue
                else
                    id = Docs.insert
                        _id: tweet.id_str
                        entities: tweet.entities
                        # tags: ['bubl','tweet']
                        body: tweet.text
                        username: username
                        timestamp: Date.now()
                        tweet_created_at: tweet.created_at
                    Meteor.call 'alchemy_tag', id, tweet.text, ->
                        console.log 'alchemy was run'
                    Meteor.call 'yaki_tag', id, tweet.text
            existing_author = Authors.findOne username:username
            if existing_author then Meteor.call 'generate_author_cloud', username
            else
                Authors.insert username: username,
                    -> 
                        Meteor.call 'generate_author_cloud', username
            ))

    sync_instagram: ->
        # console.log 'firing sync_instagram with ', instagram
        
        instagram = Meteor.user().services.instagram
        
        Meteor.call 'call_instagram', "https://api.instagram.com/v1/users/self/media/recent/?access_token=#{instagram.accessToken}&count=-1"
        
    call_instagram: (url)->
        # increment++
        console.log 'calling instagram'
        HTTP.call 'GET', url, (err,res) ->
            if err then console.log err
            else
                console.log 'instagram response is: ', res
                for post in res.data.data
                    # console.log post
            
                    found_post = Docs.findOne post.id
                    if found_post
                        console.log 'found duplicate ', post.id
                        continue
                    else
                        id = Docs.insert
                            _id: post.id
                            type: 'instagram'
                            tags: post.tags
                            body: post.caption.text
                            thumbnail_url: post.images.thumbnail.url
                            username: post.user.username
                            timestamp: Date.now()
                            post_created_at: post.created_time
                if res.data.pagination
                    console.log "about to recursively call instagram again with #{res.data.pagination.next_url}"
                    Meteor.call 'call_instagram', res.data.pagination.next_url
                else console.log 'end of pagination' 


    yaki_tag: (id, body)->
        doc = Docs.findOne id
        suggested_tags = Yaki(body).extract()
        cleaned_suggested_tags = Yaki(suggested_tags).clean()
        uniqued = _.uniq(cleaned_suggested_tags)
        lowered = uniqued.map (tag)-> tag.toLowerCase()

        #lowered = tag.toLowerCase() for tag in uniqued

        Docs.update id,
            $set: yaki_tags: lowered
            $addToSet: tags: $each: lowered


    alchemy_tag: (id, body)->
        doc = Docs.findOne id
        encoded = encodeURIComponent(body)

        # result = HTTP.call 'POST', 'http://gateway-a.watsonplatform.net/calls/text/TextGetCombinedData', { params:
        HTTP.call 'POST', 'http://access.alchemyapi.com/calls/html/HTMLGetCombinedData', { params:
            apikey: '6656fe7c66295e0a67d85c211066cf31b0a3d0c8'
            # text: encoded
            html: body
            outputMode: 'json'
            # extract: 'entity,keyword,title,author,taxonomy,concept,relation,pub-date,doc-sentiment' }
            extract: 'keyword' }
            , (err, result)->
                if err then console.log err
                else
                    console.log 'alchemy result:', result
                    keyword_array = _.pluck(result.data.keywords, 'text')
                    lowered_keywords = keyword_array.map (tag)-> tag.toLowerCase()

                    Docs.update id,
                        $set: alchemy_tags: lowered_keywords
                        $addToSet: tags: $each: lowered_keywords

    clear_my_docs: ->
        Docs.remove({username: Meteor.user().profile.name})

    check_in: (location)->
        Meteor.users.update Meteor.userId(),
            $set: location: location

    generate_user_cloud: (username)->
        match = {}
        match.username = username
        console.log match
        cloud = Docs.aggregate [
            { $match: match }
            { $project: tags: 1 }
            { $unwind: '$tags' }
            { $group: _id: '$tags', count: $sum: 1 }
            { $sort: count: -1, _id: 1 }
            { $limit: 10 }
            { $project: _id: 0, name: '$_id', count: 1 }
            ]
        console.log 'user cloud', cloud
        
        list = (tag.name for tag in cloud)
        
        Meteor.users.update Meteor.userId(),
            $set:
                cloud: cloud
                list: list


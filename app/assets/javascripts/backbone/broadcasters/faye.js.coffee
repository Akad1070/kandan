class Kandan.Broadcasters.FayeBroadcaster

  constructor: ()->
    @faye_client = new Faye.Client("/remote/faye")
    @faye_client.disable('websocket')
    authExtension = {
      outgoing: (message, callback)->
        message['ext'] = {
          auth_token: Kandan.Helpers.Users.currentUser().auth_token
        }
        callback(message)
    }
    @faye_client.addExtension(authExtension)

    @faye_client.bind "transport:down", ()->
      console.log "Comm link to Cybertron is down!"

    @faye_client.bind "transport:up", ()->
      console.log "Comm link is up!"

    @faye_client.subscribe "/app/user_activities", (data)=>
      $(document).data('active_users', data.data.active_users)
      Kandan.Helpers.Channels.add_activity({
        user: data.data.user,
        action: data.event.split("#")[1]
      })

    @faye_client.subscribe "/app/channel_activities", (data)=>
      # TODO action makes way for channel rename to be added later
      Kandan.Helpers.Channels.deleteChannelById(data.channel.id) if data.action == "delete"


  subscribe: (channel)->
    subscription = @faye_client.subscribe channel, (data)=>
      Kandan.Helpers.Channels.add_activity(data)
    subscription.errback(()->
      alert "Oops! could not connect to the server"
    )

  publish: (activityAttributes)->
    console.log "publishing...", activityAttributes
    @faye_client.publish "/channels/#{activityAttributes.channel_id}", activityAttributes
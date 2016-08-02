@Docs = new Meteor.Collection 'docs'
@Tags = new Meteor.Collection 'tags'
@Usernames = new Meteor.Collection 'usernames'
@Authors = new Meteor.Collection 'authors'



FlowRouter.route '/',
    name: 'home'
    action: ->
        BlazeLayout.render 'layout', main: 'home'


FlowRouter.route '/profile',
    name: 'profile'
    action: ->
        BlazeLayout.render 'layout', main: 'profile'



AccountsTemplates.configure
    defaultLayout: 'layout'
    forbidClientAccountCreation: true
    # defaultLayoutRegions: header: 'header'
    defaultContentRegion: 'main'
    showForgotPasswordLink: false
    overrideLoginErrors: true
    enablePasswordChange: true
    sendVerificationEmail: false
    showAddRemoveServices: true
    lowercaseUsername: true
    confirmPassword: true
    continuousValidation: true
    homeRoutePath: '/'
    showPlaceholders: true
    negativeValidation: true
    positiveValidation: true
    negativeFeedback: false
    positiveFeedback: false
    texts:
        title:
            changePwd: 'Change password'
            forgotPwd: 'Forgot password?'
            resetPwd: 'Reset password'
            signIn: 'Sign in'
            signUp: 'Sign up'
            verifyEmail: 'Verify Email'
        button:
            changePwd: 'Change password'
            enrollAccount: 'Enroll Text'
            forgotPwd: 'Send reset link'
            resetPwd: 'Reset Password'
            signIn: 'Sign in'
            signUp: 'Sign up'

# configuring useraccounts for login with both username or email
pwd = AccountsTemplates.removeField('password')
AccountsTemplates.removeField 'email'
AccountsTemplates.addFields [
    # {
    #     _id: 'email'
    #     type: 'email'
    #     required: false
    #     displayName: 'Email'
    #     re: /.+@(.+){2,}\.(.+){2,}/
    #     errStr: 'Invalid email'
    # }
    {
        _id: 'username'
        type: 'text'
        displayName: 'Username'
        required: true
        minLength: 3
    }
    {
        _id: 'username_and_email'
        placeholder: 'Username or email'
        type: 'text'
        required: true
        displayName: 'Login'
    }
    pwd
]
# enable preconfigured Flow-Router routes by useraccounts:flow-router.
# AccountsTemplates.configureRoute 'changePwd'
# AccountsTemplates.configureRoute 'forgotPwd'
# AccountsTemplates.configureRoute 'resetPwd'
AccountsTemplates.configureRoute 'signIn'
# AccountsTemplates.configureRoute 'signUp'
# AccountsTemplates.configureRoute 'verifyEmail'
# AccountsTemplates.configureRoute('enrollAccount'); // for creating passwords after logging first time


# orig_updateOrCreateUserFromExternalService = Accounts.updateOrCreateUserFromExternalService

# Accounts.updateOrCreateUserFromExternalService = (serviceName, serviceData, options) ->
#     loggedInUser = Meteor.user()
#     if loggedInUser and typeof loggedInUser.services[serviceName] == 'undefined'
#         setAttr = {}
#         setAttr['services.' + serviceName] = serviceData
#         Meteor.users.update loggedInUser._id, $set: setAttr
#     orig_updateOrCreateUserFromExternalService.apply this, arguments
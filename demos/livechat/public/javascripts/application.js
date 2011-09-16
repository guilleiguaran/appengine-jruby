var Template = {
    apply: function(string, parameters) {
        return string.replace(/#\{(.+?)\}/g, function(_, key) {
            return parameters[key];
        });
    }
};


function MessageQueue(opts){
    this.chatId = opts.chatId;
    this.lastMessageId = opts.lastMessageId;
    this.lastMessageSequence = opts.lastMessageSequence;
    this.fetchRate = opts.fetchRate; //milliseconds
    this.renderRate = opts.renderRate; //milliseconds
    this.messages = []; //blank array
    MessageQueue.instance = this;
};

MessageQueue.prototype = {

    startFetchMessages: function(){
        MessageQueue.fetchMessages();

    },
    startRenderMessages: function(){
        MessageQueue.renderMessage();
    }
};

MessageQueue.fetchMessages = function(){
    $.ajax({
        url: '/chat/' + MessageQueue.instance.chatId + '/messages',
        dataType: 'json',
        data: {last_message_id: MessageQueue.instance.lastMessageId, last_message_sequence: MessageQueue.instance.lastMessageSequence},
        success: function(data, status){
            for(var i = data.messages.length -1 ; i >= 0; i--){
                MessageQueue.instance.messages.push(data.messages[i]);
            }
            if(data.lastMessageId){
                MessageQueue.instance.lastMessageId = data.lastMessageId;
            }
            if(data.lastMessageSequence){
                MessageQueue.instance.lastMessageSequence = data.lastMessageSequence;
            }
            //put in timeout again
            setTimeout('MessageQueue.fetchMessages()', MessageQueue.instance.fetchRate);
        },
        error: function(){
            alert('Cannot fetch message');
        }

    });
};

MessageQueue.renderMessage = function(){
    message = MessageQueue.instance.messages.shift();
    if(message){
        var escapedMessage = {messageText: escape(message.messageText), userName: escape(message.userName), dateTime: message.dateTime};
        $('#chatMessageList').append(Template.apply(MessageQueue.messageTemplate, escapedMessage));
        $('#chatMessageList').attr({ scrollTop: $('#chatMessageList').attr("scrollHeight") });
    }
    setTimeout('MessageQueue.renderMessage()', MessageQueue.instance.renderRate);
};


function Pinger(opts){
    this.chatId = opts.chatId;
    this.pingRate = opts.pingRate;
    this.chatUserId = opts.chatUserId;
    this.pingUrl = '/chat/'+this.chatId+'/ping';
    this.started = false;
    Pinger.instance = this;
};

Pinger.prototype = {
    callHome: function(){
        this.started = true;
        if(this.chatUserId){
            $.ajax({
                type: 'POST',
                url: this.pingUrl,
                dataType: 'json',
                data: {chat_user_id: this.chatUserId},
                success: function(data, status){
                    setTimeout('Pinger.instance.callHome()', Pinger.instance.pingRate);
                },
                error: function(data, status){}

            });

        }else{
            setTimeout('Pinger.instance.callHome()', this.pingRate);
        }
    }
};

function UserList(opts){
    this.fetchRate = opts.fetchRate;
    this.chatId = opts.chatId;
    this.chatUrl = '/chat/'+this.chatId+'/users';
    this.currentChatUsers = opts.currentChatUsers;
    UserList.instance = this;
};

UserList.prototype = {
    renderList: function(data){
        var htmlOutput = ''
        for(var i = 0; i < data.length; i ++){
            var escapedUser = {userName: escape(data[i].userName)};
            htmlOutput += Template.apply(UserList.userTemplate, escapedUser);
        }
        $('#chatUserList').html(htmlOutput);
    },
    updateStats: function(data){
        var result = UserList.diff(this.currentChatUsers, data);
        var loggedOffUsers = result[0];
        var newUsers = result[1];
        if(loggedOffUsers.length || newUsers.length){
            if(loggedOffUsers.length){
                var loggedOffUserNames = [];
                for(var i = 0; i < loggedOffUsers.length; i++){
                    loggedOffUserNames.push(escape(loggedOffUsers[i].userName));
                }
                $('#chatMessageList').append('<div>' + loggedOffUserNames.join(', ') + ' left the chat room</div>');
            }
            if(newUsers.length){
                var newUserNames = [];
                for(var i = 0; i < newUsers.length; i++){
                    newUserNames.push(escape(newUsers[i].userName));
                }
                $('#chatMessageList').append('<div>'+ newUserNames.join(', ') + ' joined the chat room</div>');
            }
            $('#chatMessageList').attr({ scrollTop: $('#chatMessageList').attr("scrollHeight") });
        }

    },
    fetchList: function(){
        var self = this;
        $.ajax({
            url: this.chatUrl,
            dataType: 'json',
            success: function(data, status){
                if(data.length){
                    self.renderList(data);
                    self.updateStats(data);
                    self.currentChatUsers = data;
                }else{
                    $('#chatUserList').html('No user found');
                }

                setTimeout('UserList.instance.fetchList()', self.fetchRate);
            },
            error: function(){

            }
        });
    }
};


UserList.diff = function(oldList, newList){
    var i=0;
    var j=0;
    var leftList = [];
    var rightList = [];
    while(i < oldList.length || j < newList.length){
        if(oldList[i] && newList[j] && oldList[i].userName == newList[j].userName){
            i++;
            j++;
        }else if((oldList[i] && newList[j] && oldList[i].userName < newList[j].userName) || j == newList.length){
            leftList.push(oldList[i]);
            i++;
        }else if((oldList[i] && newList[j] && oldList[i].userName > newList[j].userName) || i == oldList.length){
            rightList.push(newList[j]);
            j++;
        }
    }
    return [leftList, rightList];
};


function Chat(opts){
    this.chatId = opts.id;
    this.pinger = opts.pinger;
    this.chatUrl = '/chat/'+this.chatId;
    this.bindListeners();
};

Chat.prototype = {
    bindListeners: function(){
        var self = this;
        $('textarea#chatMessage').keydown(function(event){
            if (event.keyCode == 13) {
                $('form#chatForm').submit();
                return false;
            }
        });

        $('form#chatForm').submit(function(){
            //check username
            var userName = $('input#userName').val();
            var chatMessage = $('textarea#chatMessage').val();
            if(userName == null || userName.match(/^\s*$/)){
                alert('Please provide a valid userName');
            }else if(chatMessage == null || chatMessage.match(/^\s*$/)){
                alert('Please provide a valid chat message');
            }else{
                //clear out chat message
                $('textarea#chatMessage').val('');
                $.ajax({
                    url: self.chatUrl,
                    type: 'POST',
                    dataType: 'json',
                    data: {
                        username: userName,
                        message: chatMessage
                    },
                    success: function(data, status){
                        self.pinger.chatUserId = data.chatUserId;
                        if(!self.pinger.started){
                            self.pinger.callHome();
                        }
                                },
                    error: function(){

                    }
            })
        }

        return false;

    });
}

};

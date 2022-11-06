# net
This is a simple implementation of a network interface with similar useage to that of js .net().

# Basic usage
Create net an instance of it.
```
var net   = new net();
```

### Server
1. Crating a server
```
var port  = 30001;
var server = net.CreateServer(function(sock){
  socket = sock;
  
  show_debug_message("A client connected");
  
  socket.on("data", function(data){
    
    //Print out message
    show_debug_message(buffer_read(data, buffer_text));
    
    //Respond to client 
    var buffer = buffer_create(9, buffer_fixed, 1);
    buffer_write(buffer, buffer_text, "what's up");
    socket.write(buffer);
    buffer_delete(buffer);
    buffer_delete(data);
  });
  
  socket.on("close", function(){
  
  });
  
  socket.on("error", function(err){
  
  });
});
```
2. Catching potential server errors.
```
server.on("error", function(err){
  show_debug_message(err);
});
```
3. Starting the server
```
server.listen(port, function(){
  show_debug_message("Server listening on port "+string(port));
});
```
4. Within a object's network event or alternative passing in a ds_map with exact contents of one the ```async_load``` ds_map refrenced. 
```
server.netEvent(async_load);
```

### Client
1. Creating a client
```
var client = net.Socket(network_type_tcp);
```
2. Create listener for server messages.
```
client.on("data", function(buff){
  show_debug_message(buffer_read(buff, buffer_text));
  buffer_delete(buff);
});
```
3. Connecting to the server
```
client.connect("127.0.0.1:30001", function(){
  show_debug_message("connected to the server");
});
```
4. Write to the server
```
var buffer = buffer_create(2, buffer_fixed, 1);
buffer_write(buffer, buffer_text, "hi");
client.write(buffer);
buffer_delete(buffer);
```
5. Within a object's network event or alternative passing in a ds_map with exact contents of one the async_load ds_map refrenced.
```
client.netEvent(async_load);
```

# Cleanup
When done make to sure clean up to prevent memory leak.
```
net.NetCleanup();
delete net;
```

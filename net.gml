// Feather disable all

/// @function		net()
/// @description	An interface useage similar to js .net(). Created 'sockets' are structs 
///					containing useful info to trigger callbacks based off listeners. Following
///					are listed methods: bgCreateServer(), bgSocket(), bgCleanup().
function net() constructor
{
	/*
	All accessiable variables, and methods are abbrivated with bg
	to avoid conflicts with other projects.
	
	All variables are to be used for READONLY purposes if wishs to write
	simply make a copy, and use that.
	*/
	
	//Socket id counter.
	static _bg_socket_id					= 0;
	//Cache for sockets.
	static _bg_sockets						= {};
	
	static _bgSocket						= function()
	{
		return {
			_bg_ip							: noone,
			_bg_port						: noone,
			_bg_type						: noone,
			_bg_on_error					: noone,
			_bg_on_data						: noone,
			_bg_on_open						: noone,
			_bg_on_close					: noone,
			_bg_on_connect					: noone,
			_bg_on_disconnect				: noone,
			_bg_on_reconnect				: noone,
			_bg_packetize					: true,
			_bg_circular_buffer				: buffer_create(0, buffer_grow, 1),
			_bg_listener_struct				: {},
			
			/// @function					write(buffer, buffer_size)
			/// @description				Sends data on the socket. Buffer must not contain any additional spacing as it uses 
			///								buffer_get_size() if size isnt provided. Depending on if packetize is enabled, if 
			///								the first 2bytes 'buffer_u16' fails to match buffer_size a newly created buffer is 
			///								created to compensate, by adding the 2byte header followed by copying the buffer into before sending. 
			///								Returns how many bytes were sent.
			/// @param {Id.Buffer}			bufferid buffer to send.
			/// @param {Real}				buffer_size Size of the buffer.
			/// @return {Real}
			write							: function(__bg_buffer, __bg_buffer_size = 0)
			{
				if(__bg_buffer_size == 0)__bg_buffer_size = buffer_get_size(__bg_buffer);
				
				if(_bg_packetize){
					if(buffer_peek(__bg_buffer, 0, buffer_u16) != __bg_buffer_size){
						var __bg_copy = buffer_create(__bg_buffer_size + 2, buffer_fixed, 1);
						buffer_write(__bg_copy, buffer_u16, __bg_buffer_size);
						buffer_copy(__bg_buffer, 0, __bg_buffer_size, __bg_copy, 2);
						__bg_buffer = __bg_copy;
						__bg_buffer_size += 2;
					}
				}
				
				return network_send_raw(id, __bg_buffer, __bg_buffer_size)	
			},
			
			/// @function					duplicate()
			/// @description				Replicates this socket struct. Returning a struct
			/// @return {Struct}
			duplicate						: function()
			{
				var __bg_new = {};
				for(var i = 0, a = variable_struct_get_names(self), s = array_length(a); i < s; i++){
					var
					k = a[i],
					v = self[$ k];
					if(typeof(v) == "method") v = method(self, asset_get_index(k));
					__bg_new[$ k] = v;
				}
				return __bg_new;
			},
			
			/// @function					on(eventName, listener)
			/// @description				Adds the callback function to the listeners struct.
			/// @param {String}				eventName Event name which to listen on.
			/// @param {Function}			listener Callback function for when event is triggered.
			on								: function(__bg_event_name, __bg_listener)
			{
				_bg_listener_struct[$ __bg_event_name] = __bg_listener;
				return self;
			},
			
			_bgDestroy						: function()
			{
				buffer_delete(_bg_circular_buffer);
			}
		}
	}
	
	/// @function							CreateServer(connectionListener)
	/// @description						Creates a server be it ctp or ws, wss.
	/// @param {Function}					connectionListener Set a listener/callback for the connection event.
	/// @return {Socket}
	static CreateServer						= function(__bg_connection_listener)
	{
		var  
		__bg_sock							= _bg_socket_id++,
		__bg_socket							= _bgSocket();
		
		_bg_sockets[$ __bg_sock]			= __bg_socket;
		
		with(__bg_socket)
		{
			_bg_self						= self;
			_bg_prototype					= other;
			_bg_socket_id					= __bg_sock;
			_bg_socket_list					= [];
			_bg_socket_array				= array_create(65535, undefined);
			_bg_connection_listener			= __bg_connection_listener;
			
			/// @function					listen()
			/// @description				Start a server listening for connections. + 4 Overload
			///								server.listen(options)
			///								server.listen(port, [callback])
			///								server.listen(port, maxclients, [callback])
			///								server.listen(port, maxclients, type, [callback])
			/// @param {real}				port Port number to listen on
			/// @param {real}				maxclients Maximum connections allowed on the server in accordance to gml.
			/// @param {Constant.network_socket} network_socket_ Type of connection.
			/// @param {Function}			callback Callback function for when server successfully started.
			/// @return {Struct}
			listen							= function()
			{
				var 
				__bg_options	= noone,
				__bg_callback	= noone;
				_bg_port		= -1;
				_bg_type		= network_socket_tcp;
				_bg_maxclients	= 100;
					
				if(argument_count > 0)
				{
					__bg_options= argument[0];
					switch(typeof(__bg_options))
					{
						case "number":
							_bg_port = __bg_options;
							break;
						case "struct":
							_bg_port		??= __bg_options[$ "port"];
							_bg_type		??= __bg_options[$ "type"];
							_bg_maxclients	??= __bg_options[$ "maxclients"];
							break;
					}
						
					if(argument_count > 1)
					{
						__bg_options	= argument[1];
						switch(typeof(__bg_options))
						{
							case "number":
								_bg_maxclients	= __bg_options;
								break;
							case "method":
								__bg_callback	= __bg_options;
								break;
						}
					}
						
					if(argument_count > 2)
					{
						__bg_options	= argument[2];
						switch(typeof(__bg_options))
						{
							case "number":
								_bg_type		= __bg_options;
								break;
							case "method":
								__bg_callback	= __bg_options;
								break;
						} 
					}
						
					if(argument_count > 3) __bg_callback = argument[3];
				}
					
				//If port is still -1. search for a open port	
				if(_bg_port != -1)
				{
					var b = network_create_server_raw(_bg_type, real(_bg_port), real(_bg_maxclients));
					if(b >= 0)
					{
						id = b;
						_bg_listening	= true;
						if(__bg_callback != noone) _bg_listener_struct[$ "open"] = __bg_callback;
						if(_bg_listener_struct[$ "open"] != undefined) _bg_listener_struct[$ "open"]();
					} else if(_bg_listener_struct[$ "error"] != undefined) _bg_listener_struct[$ "error"]({"message": "Unable to bind to port "+string(_bg_port)});
				}else{
					var __bg_server = -1;
											
					try{__bg_server = network_create_server_raw(_bg_type, _bg_port, _bg_maxclients);}catch(e){}
											
					while (__bg_server < 0 && _bg_port < 65535)
					{
						_bg_port++
						try{__bg_server = network_create_server_raw(_bg_type, _bg_port, _bg_maxclients);}catch(e){}
					}
					if(__bg_server < 0)
					{
						if(_bg_listener_struct[$ "error"] != undefined) _bg_listener_struct[$ "error"]({"message": "Unable to find a free port"});	
					}else{
						id				= __bg_server;
						_bg_listening	= true;
							
						if(__bg_callback != noone) _bg_listener_struct[$ "open"] = __bg_callback;
						if(_bg_listener_struct[$ "open"] != undefined) _bg_listener_struct[$ "open"]();
					}
				}
				return self;
			};
		
			/// @function					broadcast(bufferid, buffer_size, list)
			/// @description				Broadcast a buffer to a list a sockets. If no size is specified buffer_get_size() will be used.
			///								If no list is specficed internal socket list will be used.
			/// @param {Id.Buffer}			bufferid  Buffer to transmit.
			/// @param {real}				size Size of buffer.
			/// @param {Array<real>}		array Array of sockets to transmit to.
			broadcast						= function(__bg_buffer, __bg_buffer_size = buffer_get_size(__bg_buffer), __bg_list = _bg_socket_list)
			{
				for(var i = 0, s = array_length(__bg_list); i < s; i++)
				{
					network_send_raw(__bg_list[i], __bg_buffer, __bg_buffer_size);
				}
				return self;
			}
			
			/// @function					close(alarm, callback)
			/// @description				Stops the server from receiving connections, booting all connected clients after alarm, returning true upon closure.
			/// @param {real}				alarm Amount of time must pass before terminating connection.
			/// @param {Function}			callback A function to call before setting the server termination alarm.
			close							= function(__bg_alarm = 0, __bg_callback = noone)
			{
				if(id != noone)
				{
					network_destroy(id);
					id				= noone;
					_bg_listening	= false;
					if(_bg_on_close != noone) _bg_on_close();
				}
				for(var i = 0, s = array_length(_bg_socket_list); i < s; i++)
				{
					var v = _bg_socket_array[_bg_socket_list[i]];
					v._bgDestroy();
					delete v;
					
				}
				_bg_socket_list  = noone;
				_bg_socket_array = noone;
				variable_struct_remove(_bg_prototype._bg_sockets, _bg_socket_id);
				_bgDestroy();
				delete _bg_self;
				return true;
			};
			
			/// @function					netEvent(async_load)
			/// @description				Connection entry point. Reads in a network_async 'async_load' like ds_map to parse accordingly and trigger listeners.
			/// @param {Id.DsMap}			async_load Ds map that would readfrom. MUST contain identical keys as network_async async_load.
			netEvent						= function(__bg_async_load = async_load)
			{
				switch(__bg_async_load[? "type"])
				{
					case network_type_data:
						with(_bg_socket_array[__bg_async_load[? "id"]])
						{
							var __bg_on_data = _bg_listener_struct[$ "data"];
							if(__bg_on_data == undefined) break;
							//Packetize tcp stream
							if(_bg_packetize)
							{
								var
								__bg_src_buffer		= __bg_async_load[? "buffer"],
								__bg_size			= __bg_async_load[? "size"];
								buffer_copy(__bg_src_buffer, 0, __bg_size, _bg_circular_buffer, buffer_get_size(_bg_circular_buffer));
								buffer_seek(_bg_circular_buffer, buffer_seek_start, 0);
								while(buffer_get_size(_bg_circular_buffer) - buffer_tell(_bg_circular_buffer) > 2)
								{
								    var 
									__bg_offset		= buffer_tell(_bg_circular_buffer),
									__bg_tar_size	= buffer_read(_bg_circular_buffer, buffer_u16);
									if(buffer_get_size(_bg_circular_buffer) - __bg_offset + 2 >= __bg_tar_size)
									{
										var __bg_copy = buffer_create(__bg_tar_size, buffer_grow, 1);
										buffer_copy(_bg_circular_buffer, __bg_offset + 2, __bg_tar_size, __bg_copy, 0);
										__bg_on_data(__bg_copy);
									    var 
										__bg_length = 2 + __bg_tar_size,
										__bg_size	= buffer_get_size(_bg_circular_buffer),
										__bg_buffer	= buffer_create(__bg_size - __bg_length, buffer_grow, 1);
									    buffer_copy(_bg_circular_buffer, __bg_length, __bg_size - __bg_length, __bg_buffer, 0);
									    buffer_delete(_bg_circular_buffer);
									    _bg_circular_buffer = __bg_buffer; 
									}else{
										buffer_seek(_bg_circular_buffer, buffer_seek_start, __bg_offset);
										break;
									}
								}
							}else __bg_on_data(__bg_async_load[? "buffer"]);
						}
						break;
					case network_type_connect:
						var 
						__bg_id							= __bg_async_load[? _bg_socket],
						__bg_socket						= _bg_prototype._bgSocket();
						__bg_socket._bg_ip				= __bg_async_load[? "ip"];
						__bg_socket._bg_port			= __bg_async_load[? "port"];
						__bg_socket.id					= __bg_id;
						_bg_socket_array[__bg_id]		= __bg_socket;
						array_push(_bg_socket_list, __bg_id);	
						_bg_connection_listener(__bg_socket);
						break;
					case network_type_disconnect:
						var 
						__bg_id		= __bg_async_load[? _bg_socket],
						__bg_sock	= _bg_socket_array[__bg_id],
						__bg_dc		= __bg_sock._bg_listener_struct[$ "close"];
						for(var i = 0, s = array_length(_bg_socket_list); i < s; i++)
						{
							if(_bg_socket_list[i] == __bg_id)
							{
								array_delete(_bg_socket_list, i, 1);
								break;	
							}
						}
						_bg_socket_array[__bg_id] = undefined;
						if(__bg_dc != undefined) __bg_dc();
						__bg_sock._bgDestroy();
						delete __bg_sock;
						break;
				}
				return self;
			};
			
			_bgCleanup						= function()
			{
				close();
			}
			return self;
		}
	}
	
	/// @function							Socket(type)
	/// @description						Creates a network socket that can be used to connect to a tcp server or p2p tranmission. Defaults to 'network_socket_tcp'.
	/// @param {Constant.network_socket}	type Type to create.
	/// @return {bgSocket}
	static Socket							= function(__bg_socket_type = network_socket_tcp)
	{
		var 
		__bg_sock							= _bg_socket_id++,
		__bg_socket							= _bgSocket();
		_bg_sockets[$ __bg_sock]			= __bg_socket;
		
		with(__bg_socket)
		{
			_bg_self						= self;
			_bg_prototype					= other;
			_bg_socket_id					= __bg_sock;
			_bg_type						= __bg_socket_type;
			_bg_is_connected				= false;
			_bg_is_open						= false;
			
			/// @function					connect(port, host, timeout, callback)
			/// @description				Attempt to connect to an endpoint. Defaults attempt to connect to localhost "127.0.0.1" + 5 Overload
			///								socket.bgConnect(options)
			///								socket.bgConnect(port, [callback])
			///								socket.bgConnect(url, [callback])
			///								socket.bgConnect(port, host, [callback])
			///								socket.bgConnect(port, host, timeout, [callback])
			/// @param {real}				port Port of targeted socket.
			/// @param {string}				host Targets ipAddress.
			/// @param {real}				timeout Timeout before retrying connection.
			/// @param {Function}			callback Callback function for when socket successfully connected.
			connect							= function()
			{
				var 
				__bg_options				= noone,
				__bg_callback				= noone;
				_bg_port					= 0;
				_bg_host					= "127.0.0.1";
				_bg_timeout					= 1000;
					
				if(argument_count > 0)
				{
					__bg_options = argument[0];
					switch(typeof(__bg_options))
					{
						case "number":
							_bg_port = __bg_options;
							break;
						case "string":
							_bg_host = string_copy(__bg_options, 1, string_pos(":", __bg_options) - 1);
							_bg_port = real(string_copy(__bg_options, string_pos(":", __bg_options) + 1, string_length(__bg_options)));
							break;
						case "struct":
							_bg_host ??= __bg_options[$ "ip"];
							_bg_port ??= __bg_options[$ "port"];
							_bg_timeout ??= __bg_options[$ "timeout"];
							break;
					}
						
					if(argument_count > 1)
					{
						_bg_port		= argument[0];
						__bg_options	= argument[1];
						switch(typeof(__bg_options))
						{
							case "string":
								_bg_host	= __bg_options;
								break;
							case "method":
								__bg_callback	= __bg_options;
								break;
						}
					}
						
					if(argument_count > 2)
					{
						__bg_options	= argument[2];
						switch(typeof(__bg_options))
						{
							case "number":
								_bg_timeout		= __bg_options;
								break;
							case "method":
								__bg_callback	= __bg_options;
								break;
						} 
					}
						
					if(argument_count > 3) __bg_callback = argument[3];
				}
					
				var __bg_socket = self[$ "id"] == undefined? network_create_socket(_bg_type): id;
				id				= __bg_socket;
					
				_bg_is_open		= true;
					
				if(__bg_callback != noone) _bg_listener_struct[$ "connect"] = __bg_callback;
				network_set_config(network_config_connect_timeout, _bg_timeout);
				network_connect_raw_async(__bg_socket, _bg_host, _bg_port);
			}
			
			/// @function					disconnect()
			/// @description				Terminates socket connection.
			disconnect						= function()
			{
				if(id != noone)
				{
					network_destroy(id);
					_bg_is_connected= false;
					_bg_is_open		= false;
				}
				_bgDestroy();
			}
			
			/// @function					isConnected()
			/// @description				Returns weather a connection has been established.
			/// @return {bool}
			isConnected						= function()
			{
				return _bg_is_connected;
			}
			
			/// @function					isOpen()
			/// @description				Returns weather the connection is open.
			/// @return {bool}
			isOpen							= function()
			{
				return _bg_is_open;	
			}
			
			/// @function					netEvent(async_load)
			/// @description				Connection entry point. Reads in a network_async 'async_load' like ds_map to parse accordingly and trigger listeners.
			/// @param {Id.DsMap}			async_load Ds map that would readfrom. MUST contain identical keys as network_async async_load.
			netEvent						= function(__bg_async_load = async_load)
			{
				switch(__bg_async_load[? "type"])
				{
					case network_type_data:
						var __bg_on_data = _bg_listener_struct[$ "data"];
						if(__bg_on_data == undefined) break;
						//Packetize tcp stream
						if(_bg_packetize)
						{
							var
							__bg_src_buffer		= __bg_async_load[? "buffer"],
							__bg_size			= __bg_async_load[? "size"];
							buffer_copy(__bg_src_buffer, 0, __bg_size, _bg_circular_buffer, buffer_get_size(_bg_circular_buffer));
							buffer_seek(_bg_circular_buffer, buffer_seek_start, 0);
							while(buffer_get_size(_bg_circular_buffer) - buffer_tell(_bg_circular_buffer) > 2)
							{
								var 
								__bg_offset		= buffer_tell(_bg_circular_buffer),
								__bg_tar_size	= buffer_read(_bg_circular_buffer, buffer_u16);
								if(buffer_get_size(_bg_circular_buffer) - __bg_offset + 2 >= __bg_tar_size)
								{
									var __bg_copy = buffer_create(__bg_tar_size, buffer_grow, 1);
									buffer_copy(_bg_circular_buffer, __bg_offset + 2, __bg_tar_size, __bg_copy, 0);
									__bg_on_data(__bg_copy);
									var 
									__bg_length = 2 + __bg_tar_size,
									__bg_size	= buffer_get_size(_bg_circular_buffer),
									__bg_buffer	= buffer_create(__bg_size - __bg_length, buffer_grow, 1);
									buffer_copy(_bg_circular_buffer, __bg_length, __bg_size - __bg_length, __bg_buffer, 0);
									buffer_delete(_bg_circular_buffer);
									_bg_circular_buffer = __bg_buffer; 
								}else{
									buffer_seek(_bg_circular_buffer, buffer_seek_start, __bg_offset);
									break;
								}
							}
						}else __bg_on_data(__bg_async_load[? "buffer"]);
						break;
					case network_type_non_blocking_connect:
						var __bg_on_connect = _bg_listener_struct[$ "connect"];
						if(__bg_on_connect != undefined)
						{
							if(__bg_async_load[? "succeeded"])
							{
								_bg_is_connected = true;
								__bg_on_connect();
							}else{
								connect(_bg_port);
								var __bg_on_error = _bg_listener_struct[$ "error"];
								if(__bg_on_error != undefined) __bg_on_error("Failed to connect to server, re attempting");
							}
						}
						break;
					case network_type_disconnect:
						var __bg_on_disconnect = _bg_listener_struct[$ "disconnect"];
						if(__bg_on_disconnect != undefined) __bg_on_disconnect();
						break;
				}
			};
			
			_bgCleanup						= function()
			{
				disconnect();
				_bgDestroy();
			}
			return self;
		}
	}
	
	/// @function							NetCleanup()
	/// @description						Terminates all 'sockets'.
	static NetCleanup						= function()
	{
		for(var i = 0, a = variable_struct_get_names(_bg_sockets), s = array_length(a); i < s; i++)
		{
			var 
			k = a[i],
			v = _bg_sockets[$ k];
			v._bgCleanup();
			delete v;
		}
		delete _bg_sockets;
	}

	//For compatibility with bgLogger
	if(!variable_instance_exists(self, "log"))
	{
		log	= function(__bg_level, __bg_message)
		{
			var 
			__bg_timestamp = "["+string(date_get_month(date_current_datetime()))+"/"+string(date_get_day(date_current_datetime()))+" "+string(date_get_hour(date_current_datetime()))+":"+string(date_get_minute(date_current_datetime()))+":"+string(date_get_second(date_current_datetime()))+"]",
			__bg_callstack = _bg_log_callstack;
		
			if(__bg_callstack) __bg_message += "\n[LOCATION]: "+string(debug_get_callstack(__bg_callstack));
		
			if(__bg_level != "FATAL" && __bg_level != "ERROR"){
				if(_bg_log_callstack) show_debug_message(__bg_timestamp+" [BG] ["+__bg_level+"] "+__bg_message);
			}else show_error(__bg_message, __bg_level == "FATAL");
		}
		warn	= function()
		{
			var r = string(argument[0]);
			for(var i = 1; i < argument_count; i++) r += " " + string(argument[i]);	
			log("WARN", r);
			return self;
		}
		fatal = function()
		{
			var r = string(argument[0]);
			for(var i = 1; i < argument_count; i++) r += " " + string(argument[i]);
			log("ERROR", r);
			return self;
		}
	}
}

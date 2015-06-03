<!DOCTYPE html>
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<link rel="stylesheet" href="./codebase/webix.css" type="text/css" media="screen" charset="utf-8">
		<script src="./codebase/webix.js" type="text/javascript" charset="utf-8"></script>
		<link rel="stylesheet" type="text/css" href="./common/samples.css">
		<style>
			#areaLeft{
				margin: 50px 10px;
				width:320px;
				height:800px;
				float: left;
			}			
			#areaStatus{
				width:800px;
				height:400px;
				float: left;			
			}
			#areaRight{
				margin: 50px 10px;
				float: left;			
			}
			.my_toolbar{
				background-image: none !important;

			}			
		</style>
		<style type="text/css">
			.webix_tree_error{
				background-image: url(./myicons/error.png)
			}
		</style>		
		<title>Manage</title>
	</head>
	<body>
	<link rel="stylesheet" type="text/css" href="./common/docs.css">
	<div class="page_header">
		<div class='page_inner_header'>
			<a href='http://webix.com'><div class='top_webix_logo'></div></a>
			运维管理系统 
		</div>
	</div>

		<script type="text/javascript">
		</script>	
		<div id="areaLeft"></div>
		<div id="areaRight">
		<table>
		<tr><div id="buttons"></div></tr>
		<tr><div id="message"></div></tr>
		<tr><td>
			<div id = "areaStatus" style="background:black">
			<p><font color="white"><span id="processInfo"></span></font></p>
			</div>
		</td></tr>
		<tr><p><font color="black"><span id="ServiceDesp"></span></font></p></tr>		
		</table>
		</div>		
		<script type="text/javascript" charset="utf-8">
			var filter = null;
			//var xmlHttp = null;
			var PhysicalView = null;
			var LogicalView = null;
			var DeployPhyTree = null;
			var DeployLogTree = null;
			var PhysicalTree = null;
			var LogicalTree = null;
			var phyInit = false;
			var logInit = false;
			var firstrun = true;
			var CurrentView = null;
			var physelectID = null;
			var logselectID = null;
			function ShowStatus(){
				var selectID = null;
				if(CurrentView == PhysicalView){
					selectID = physelectID;
				}else{
					selectID = logselectID;
				} 
				if(!selectID){
					selectID = CurrentView.getFirstId();
					CurrentView.select(selectID);
				}
				var str = '';
				if(selectID){
					var item = CurrentView.getItem(selectID);
					var root;
					if(item.root){
						root = item;
					}else{
						root = CurrentView.getItem(CurrentView.getParentId(selectID));
					}
					var flag = null;
					if(root){
						if(CurrentView == PhysicalView){
							var machine = PhysicalTree[root.value];
							if(machine){
								var status = machine.machine;
								for(var i = 0,len = status.length; i < len; i++){
									str = str + status[i] + '</br>';
								}
								str = str + "-------------------------------process------------------------------- </br>";
								var process = machine.process;
								if(process){
									if(root.id == selectID){
										var c = 0;											
										for (var key in process){
											str = str + "pid:" + process[key].pid + ",usr:" + process[key].usr;
											str = str + ",cpu:" + process[key].cpu + ",mem:" + process[key].mem;
											str = str + ",cmd:" + process[key].cmd + "</br>";
											c++;
										}
										if(c == DeployPhyTree[root.value].length)
											flag= [0,1,1];
										else if(c == 0 &&  DeployPhyTree[root.value].length > 0)
											flag= [1,0,0];
										else
											flag= [1,1,1];
										/*if(c != DeployPhyTree[root.value].length){
											flag= [1,1,1];
										}else{
											flag= [0,1,1];
										}*/			
									}else if(process[item.value]){
										str = str + "pid:" + process[item.value].pid + ",usr:" + process[item.value].usr;
										str = str + ",cpu:" + process[item.value].cpu + ",mem:" + process[item.value].mem;
										str = str + ",cmd:" + process[item.value].cmd + "</br>";
										flag= [0,1,1];										
									}else{
										flag= [1,0,0];
									}
								}else{
									flag= [1,0,0];		
								}											
							}else{
								flag= [0,0,0];
							}
						}else{
							var group = LogicalTree[root.value];
							if(group){
								if(root.id == selectID){
									var c = 0;											
									for (var key in group){
										str = str + "pid:" + group[key][1].pid + ",usr:" + group[key][1].usr;
										str = str + ",cpu:" + group[key][1].cpu + ",mem:" + group[key][1].mem;
										str = str + ",cmd:" + group[key][1].cmd + "</br>";
										c++;
									}
									if(c == DeployLogTree[root.value].length){
										flag= [0,1,1];
									}else if(c == 0 &&  DeployLogTree[root.value].length > 0){
										flag= [1,0,0];
									}else{
										flag= [1,1,1];	
									}										
								}else if(group[item.value]){
									str = str + "pid:" + group[item.value][1].pid + ",usr:" + group[item.value][1].usr;
									str = str + ",cpu:" + group[item.value][1].cpu + ",mem:" + group[item.value][1].mem;
									str = str + ",cmd:" + group[item.value][1].cmd + "</br>";
									flag= [0,1,1];									
								}else{
									flag= [1,0,0];	
								}		
							}else{
								flag= [0,0,0];
							}
						}	
					}
				}
				if(flag){
					flag[0]  == 0 ?  $$("Start").disable() : $$("Start").enable();
					flag[1]  == 0 ?  $$("Stop").disable() : $$("Stop").enable();
					flag[2]  == 0 ?  $$("Kill").disable() : $$("Kill").enable();
				}else{
					$$("Start").disable();
					$$("Stop").disable();
					$$("Kill").disable();	
				}
				document.getElementById("processInfo").innerHTML = str;
			}						
			function createXMLHttpRequest(){
				if(window.ActiveXObject){
					return new ActiveXObject("Microsoft.XMLHTTP");
				}
				else if(window.XMLHttpRequest){
					return new XMLHttpRequest();
				}
			}
			function fetchdata(){
				var request = createXMLHttpRequest();
				var url="info.php";
				request.open("GET",url,true);
				request.setRequestHeader("Content-Type","application/x-www-form-urlencoded; charset=UTF-8");		
				request.onreadystatechange = callback;
				request.send(null);
			}
			function buildPhyTree(machinedata){
				function match(name,array){
					for(var i = 0,len = array.length; i < len; ++i){
						if(array[i].cmd.search(name) > 0){
							return array[i];									
						}
					}
					return null;
				}
				PhysicalTree = {};
				for(var i = 0,len1 = machinedata.length; i < len1; i++){
					PhysicalTree[machinedata[i].ip] = {};
					var tmp1 = PhysicalTree[machinedata[i].ip];
					tmp1.machine	= machinedata[i].status[0];
					tmp1.process = {};
					var tmp2 = DeployPhyTree[machinedata[i].ip]
					var tmp3 = machinedata[i].status[1];
					for(var j = 0,len2 = tmp2.length; j < len2;j++){
						var process = match(tmp2[j][0],tmp3);
						if(process){
							tmp1.process[tmp2[j][0]] = process;
						}
					}	
				}
			}
			function buildLogicalTree(){
				LogicalTree = {};
				for (var key1 in DeployLogTree){
					for(var key2 in PhysicalTree){
						var ip = key2;
						var process = PhysicalTree[key2].process;
						for(var key3 in process){
							if(process[key3].cmd.search(key1) > 0){
								if(!LogicalTree[key1]){
									LogicalTree[key1] = {};
								}
								LogicalTree[key1][key3] = [ip,process[key3]];			
							}
						}
					}
				}				
			}
			function buildDeployPhyTree(deploydata){
				DeployPhyTree = {};
				for(var i = 0,len1 = deploydata.length; i < len1; i++){
					var tmp1 = deploydata[i].service;
					var group = deploydata[i].groupname;
					for(var j = 0,len2 = tmp1.length; j < len2; j++){
						var tmp2 = DeployPhyTree[tmp1[j].ip];
						if(!tmp2){
							tmp2 = [];
							DeployPhyTree[tmp1[j].ip] = tmp2;
						}
						tmp2.push([tmp1[j].logicname,group]);	
					}		
				}
			}
			function buildDeployLogTree(deploydata){
				DeployLogTree = {};
				for(var i = 0,len1 = deploydata.length; i < len1; i++){
					var tmp1 = deploydata[i].service;
					var tmp2 = [];
					DeployLogTree[deploydata[i].groupname] = tmp2;
					for(var j = 0,len2 = tmp1.length; j < len2; j++){
						tmp2.push(tmp1[j].logicname);
					}								
				}								
			}
			function buildPhyView(){
				for (var key in DeployPhyTree){
					var services = DeployPhyTree[key];
					var rootitem = {id:key,value:key,root:true};
					var rootid = PhysicalView.add(rootitem, null, 0);
					var err = false;					
					var goterror = false;
					for(var i = 0,len = services.length; i < len; i++){
						var item;
						var icon;
						var ip = key;
						var logicname = services[i][0];
						if(PhysicalTree[ip] && PhysicalTree[ip].process[logicname]){
							icon = "";
						}else{
							icon = "error";
							goterror = true;
						}
						item = {id:key + ":" + services[i][0],value:services[i][0],icon:icon,group:services[i][1]};
						var id = PhysicalView.add(item, null, rootid);
					}
					if(goterror){
						PhysicalView.updateItem(rootid, {icon:"error"});
					}					
				}
			}						
			function buildLogView(){
				for (var key in DeployLogTree){
					var tmp1 = DeployLogTree[key];
					var rootitem = {id:key,value:key,root:true};
					var rootid = LogicalView.add(rootitem, null, 0);
					var goterror = false;
					for(var j = 0,len2 = tmp1.length; j < len2; j++){
						var item;
						var icon;
						var group = key;
						var logicname = tmp1[j];
						if(LogicalTree[group] && LogicalTree[group][logicname]){
							icon = "";
						}else{
							icon = "error";
							goterror = true;
						}
						item = {id:group+":"+tmp1[j],value:tmp1[j],icon:icon};						
						var id = LogicalView.add(item, null, rootid);					
					}
					if(goterror){
						LogicalView.updateItem(rootid, {icon:"error"});
					}					
				}
			}
			function updatePhyView(){
				for (var key in DeployPhyTree){
					var services = DeployPhyTree[key];
					var goterror = false;
					var rootitem = PhysicalView.getItem(key); 
					if(!rootitem){
						//new root
					}
					var icon;
					for(var i = 0,len = services.length; i < len; i++){
						var ip = key;
						var logicname = services[i][0];
						var id = key + ":" + services[i][0]
						var item = PhysicalView.getItem(id);
						if(!item){
							//new item
						} 
						if(PhysicalTree[ip] && PhysicalTree[ip].process[logicname]){
							icon = "";
						}else{
							icon = "error";
							goterror = true;
						}
						if(item.icon != icon)
							PhysicalView.updateItem(id,{icon:icon});
					}
					if(goterror){
						icon = "error";
					}else{
						icon = "";
					}
					if(rootitem.icon != icon){
						PhysicalView.updateItem(key, {icon:icon});
					}				
				}				
			}
			function updateLogView(){
				for (var key in DeployLogTree){
					var tmp1 = DeployLogTree[key];
					var goterror = false;
					var rootitem = LogicalView.getItem(key);
					if(!rootitem){
						//new root
					} 
					var icon;
					for(var j = 0,len2 = tmp1.length; j < len2; j++){
						var group = key;
						var logicname = tmp1[j];
						var id = group+":"+tmp1[j];
						var item = LogicalView.getItem(id);
						if(!item){
							//new item
						}
						if(LogicalTree[group] && LogicalTree[group][logicname]){
							icon = "";
						}else{
							icon = "error";
							goterror = true;
						}
						if(item.icon != icon)					
							LogicalView.updateItem(group+":"+tmp1[j], {icon:icon});					
					}
					if(goterror){
						icon = "error";
					}else{
						icon = "";
					}
					if(rootitem.icon != icon){
						LogicalView.updateItem(key, {icon:icon});
					}					
				}
			}
			function callback(){
				if(this.readyState == 4){
					if(this.status == 200){
						var info = JSON.parse(this.responseText);
						var deploydata = info.deployment;
						var machinedata = info.machine_status;																
						if(firstrun){
							//webix.message("first");
							buildDeployPhyTree(deploydata);
							buildPhyTree(machinedata);
							buildPhyView();	
							buildDeployLogTree(deploydata);
							buildLogicalTree();
							buildLogView();
						}else{
							buildPhyTree(machinedata);
							buildLogicalTree();
							updatePhyView();
							updateLogView();
						}
						ShowStatus();				
						firstrun = false;
						setTimeout("fetchdata()",1000);
					}
				}
			}
			function buttonclick(id){
				function buttoncallback(){
					if(this.readyState == 4){
						if(this.status == 200){
							document.getElementById("message").innerHTML = this.responseText;
						}
					}
				}				
				if(confirm("confirm?")){
					var selectID = null;
					if(CurrentView == PhysicalView){
						selectID = physelectID;
					}else{
						selectID = logselectID;
					}
					if(!selectID){
						selectID = CurrentView.getFirstId();
						CurrentView.select(selectID);
					}
					//webix.message("1");
					if(selectID){
						var item = CurrentView.getItem(selectID);
						var root;
						if(item.root){
							root = item;
						}else{
							root = CurrentView.getItem(CurrentView.getParentId(selectID));
						}
						if(root){	
							var ip = false;
							var group = false;
							var logicname = false;				
							if(CurrentView == PhysicalView){
								ip = root.value;
							}else if (CurrentView == LogicalView){
								group = root.value;
							}
							if(root.id != selectID && item){
								logicname = item.value;
								if(!group) group = item.group;
							}
							//constructor http request
							var request = createXMLHttpRequest();
							var url="control_action.php";
							request.open("POST",url,true);
							request.setRequestHeader("Content-Type","application/x-www-form-urlencoded; charset=UTF-8");		
							request.onreadystatechange = buttoncallback;
							//webix.message("1");
							var op = {};
							op['op'] = id;
							//webix.message("2");
							if(ip) op['ip'] = ip;
							//webix.message("3");
							if(group) op['group'] = group;
							//webix.message("4");
							if(logicname) op['logicname'] = logicname;
							//webix.message("5");
							var str = JSON.stringify(op);
							request.send("op=" + str);						
						}
					}
					//webix.message("3");
				}
			}						
			webix.ui({
				id:"LeftTree",
				container: "areaLeft",
				borderless:true, 
				view:"tabview",							
				cells:[
					{
						header:"Physical View",							
						body:{
							select:true,
							view:"tree",
							ready:function(){ 
								PhysicalView = this;
								CurrentView = PhysicalView;
								phyInit = true;
								if(logInit){
									fetchdata();
								}
							},							
							on:{
								"onAfterSelect":function(id){
									physelectID = id;
									//var item = this.getItem(id)
									//webix.message(item.group)
									fetchdata();

								}
							},
							data:[]
						},
					},
					{
						header:"Logical View",
						body:{
							select:true,
							view:"tree",
							ready:function(){ 
								LogicalView = this;
								logInit = true;
								if(phyInit){
									fetchdata();
								}								
							},							
							on:{
								"onAfterSelect":function(id){
									logselectID = id;
									fetchdata();
								}
							},
							data:[]
						},
					},							
				]
			});
			webix.ui({
				container: "buttons",
                			view:"toolbar" ,css:"my_toolbar", id:"button_bar", cols:[
                    			{ view:"button", value: 'Start', id: 'Start', width:100, click:"buttonclick"},
                    			{ view:"button", value: 'Stop', id: 'Stop', width:100, click:"buttonclick"},
                    			{ view:"button", value: 'Kill', id: 'Kill', width:100, click:"buttonclick"}
                    			]
                    		});			
			$$("LeftTree").getChildViews()[1].attachEvent("onViewChange",function(id){
			        if(CurrentView == LogicalView)
			        	CurrentView = PhysicalView;
			       else
			       	CurrentView = LogicalView;
			       fetchdata();
			});
			//$$("Start").disable();
			
		</script>
	</body>
</html>

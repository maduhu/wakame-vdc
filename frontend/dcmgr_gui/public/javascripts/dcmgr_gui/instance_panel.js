DcmgrGUI.prototype.instancePanel = function(){
  var total = 0;
  var maxrow = 10;
  var page = 1;
  var list_request = { 
    "url" : DcmgrGUI.Util.getPagePath('/instances/list/',1),
    "data" : DcmgrGUI.Util.getPagenateData(page,maxrow)
  };
  
  DcmgrGUI.List.prototype.getEmptyData = function(){
    return [{
      "id":'',
      "instance_id":'',
      "owner":'',
      "wmi_id":'',
      "state":'',
      "private_ip":'',
      "type":''
    }]
  }
  
  DcmgrGUI.Detail.prototype.getEmptyData = function(){
    return {
      "instance_id":'-',
      "wmi_id":'-',
      "zone":'-',
      "security_groups":'-',
      "type":'-',
      "status":'-',
      "owner":'-'
    }
  }
  
  var close_button_name = $.i18n.prop('close_button');
  var terminate_button_name = $.i18n.prop('terminate_button');
  var reboot_button_name = $.i18n.prop('reboot_button');

  var c_pagenate = new DcmgrGUI.Pagenate({
    row:maxrow,
    total:total
  });
  
  var c_list = new DcmgrGUI.List({
    element_id:'#display_instances',
    template_id:'#instancesListTemplate',
    maxrow:maxrow,
    page:page
  });
  
  var detail_filter = new DcmgrGUI.Filter();
  detail_filter.add(function(data){
    data.item.memory_size = data.item.memory_size + 'MB';
    return data;
  });
    
  c_list.setDetailTemplate({
    template_id:'#instancesDetailTemplate',
    detail_path:'/instances/show/',
    filter: detail_filter
  });
  
  c_list.element.bind('dcmgrGUI.contentChange',function(event,params){
    var instance = params.data.instance;
    c_pagenate.changeTotal(instance.owner_total);
    c_list.setData(instance.results);
    c_list.multiCheckList(c_list.detail_template);
  });
  
  c_list.filter.add(function(data){
    var results = data.instance.results;
    var size = results.length;
    for(var i = 0; i < size; i++) {
      results[i].result.memory_size = results[i].result.memory_size + 'MB';
    }
    return data;
  });
  
  var bt_refresh  = new DcmgrGUI.Refresh();
  
  var instance_action_helper = function(action){
    
    var instances = $(this).find('#instances').find('li');
    var ids = [];
    
    $.each(instances, function() {
      ids.push($(this).text());
    });

    var data = $.param({ids:ids});
    
    $.ajax({
       "type": "POST",
       "async": true,
       "url": '/instances/'+ action,
       "dataType": "json",
       "data": data,
       success: function(json, status) {
         bt_refresh.element.trigger('dcmgrGUI.refresh');
       }
     });
    
    $(this).dialog("close");
  };
  
  var bt_instance_start = new DcmgrGUI.Dialog({
    target:'.start_instances',
    width:400,
    height:200,
    title:'Start Instances',
    path:'/start_instances',
    button:{
     "Close": function() { $(this).dialog("close"); },
     "Yes, Start": function() { 
       $(this).dialog("close");
     }
    }
  });
  
  var bt_instance_stop = new DcmgrGUI.Dialog({
     target:'.stop_instances',
     width:400,
		 height:200,
		 title:'Stop Instances',
		 path:'/stop_instances',
		 button:{
			"Close": function() { $(this).dialog("close"); },
			"Yes, Stop": function() {
			  $(this).dialog("close");
			}
		}
  });
  
  var instance_reboot_buttons = {};
  instance_reboot_buttons[close_button_name] = function() { $(this).dialog("close"); }
  instance_reboot_buttons[reboot_button_name] = function() {
    instance_action_helper.call(this,'reboot');
  }
  var bt_instance_reboot = new DcmgrGUI.Dialog({
     target:'.reboot_instances',
     width:400,
     height:200,
     title:$.i18n.prop('reboot_instances_header'),
     path:'/reboot_instances',
     button: instance_reboot_buttons
  });
  
  var instance_terminate_buttons = {};
  instance_terminate_buttons[close_button_name] = function() { $(this).dialog("close"); };
  instance_terminate_buttons[terminate_button_name] = function() {
    instance_action_helper.call(this,'terminate');
  }
  var bt_instance_terminate = new DcmgrGUI.Dialog({
    target:'.terminate_instances',
    width:400,
    height:200,
    title:$.i18n.prop('terminate_instances_header'),
    path:'/terminate_instances',
    button: instance_terminate_buttons
  });
  
  bt_instance_start.target.bind('click',function(){
    bt_instance_start.open(c_list.getCheckedInstanceIds());
  });

  bt_instance_stop.target.bind('click',function(){
    bt_instance_stop.open(c_list.getCheckedInstanceIds());
  });

  bt_refresh.element.bind('dcmgrGUI.refresh',function(){
    c_list.page = c_pagenate.current_page;
    list_request.url = DcmgrGUI.Util.getPagePath('/instances/list/',c_list.page);
    list_request.data = DcmgrGUI.Util.getPagenateData(c_pagenate.start,c_pagenate.row);
    c_list.element.trigger('dcmgrGUI.updateList',{request:list_request})
    
    //update detail
    $.each(c_list.checked_list,function(check_id,obj){
      $($('#detail').find('#'+check_id)).remove();
      c_list.checked_list[check_id].c_detail.update({
        url:DcmgrGUI.Util.getPagePath('/instances/show/',check_id)
      },true);
    });
  });

  c_pagenate.element.bind('dcmgrGUI.updatePagenate',function(){
    c_list.clearCheckedList();
    $('#detail').html('');
    bt_refresh.element.trigger('dcmgrGUI.refresh');
  });
  
  var selectmenu = $('#instance_action').selectmenu({
    width: 150,
    menuWidth: 150,
    handleWidth: 26,
    style:'dropdown',
    select: function(event){
      var select_action = $(this).val()
      if (select_action == "terminate") {
        bt_instance_terminate.open(c_list.getCheckedInstanceIds());
      }else if(select_action == "reboot") {
        bt_instance_reboot.open(c_list.getCheckedInstanceIds());
      }
    }
  });
  $(bt_refresh.target).button({ disabled: false });
  selectmenu.data('selectmenu').disableButton();
  
  dcmgrGUI.notification.subscribe('checked_box', selectmenu.data('selectmenu'), 'enableButton');
  dcmgrGUI.notification.subscribe('unchecked_box', selectmenu.data('selectmenu'), 'disableButton');
  dcmgrGUI.notification.subscribe('change_pagenate', selectmenu.data('selectmenu'), 'disableButton');
  
  //list
  c_list.setData(null);
  c_list.update(list_request,true);
}
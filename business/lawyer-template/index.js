$('#nav-tab a').on('click', function(e){
    e.preventDefault();

    const currentTabId =  $(this).attr('id');
    const currentTab = $(`#${currentTabId}`)

    $(currentTab).addClass('active').siblings().removeClass('active');
    
    const elemId = ($(this).attr('href'));
  
    $(`${elemId}`).tab('show').addClass('show').siblings().removeClass('show');
})





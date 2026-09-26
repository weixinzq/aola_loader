package mmo.petfightnew.common.fightcontroller.fightinfopanel.tab
{
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import mmo.common.panel.OperableView;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.data.IPetSkillMesService;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.common.FIP_Info;
   import mmo.play.actthings.helper.ActComHelper;
   
   public class FIP_TabBase extends OperableView
   {
      
      protected var _pmSvr:IPMService;
      
      protected var _petMesSvr:IPetSkillMesService;
      
      protected var _refreshAllTabCommonViewFunc:Function;
      
      protected var _tabIndex:int;
      
      protected var _info:FIP_Info;
      
      public function FIP_TabBase(param1:FIP_Info, param2:int, param3:Function = null)
      {
         super();
         this._info = param1;
         this._tabIndex = param2;
         this._refreshAllTabCommonViewFunc = param3;
      }
      
      override public function registerView(param1:Sprite) : void
      {
         this._view = param1;
         if(this._view)
         {
            this.init();
         }
      }
      
      override protected function initComponents() : void
      {
         super.initComponents();
         this._pmSvr = ServiceContainer.instance.getService(IPMService) as IPMService;
         this._petMesSvr = ServiceContainer.instance.getService(IPetSkillMesService) as IPetSkillMesService;
      }
      
      protected function closeAll() : void
      {
         ModalDialogManager.getInstance().clearAll();
      }
      
      override protected function refreshView() : void
      {
         super.refreshView();
         ActComHelper.applyFunc(this._refreshAllTabCommonViewFunc);
      }
      
      override protected function addListeners() : void
      {
         super.addListeners();
         this.regClickFunc(/^btn[a-zA-Z0-9_]+/,this.onClickButton,true,null,this);
      }
      
      protected function onClickButton(param1:DisplayObject) : void
      {
      }
      
      public function show() : void
      {
         this._view.visible = true;
         this.refreshView();
      }
      
      public function hide() : void
      {
         this._view.visible = false;
      }
   }
}


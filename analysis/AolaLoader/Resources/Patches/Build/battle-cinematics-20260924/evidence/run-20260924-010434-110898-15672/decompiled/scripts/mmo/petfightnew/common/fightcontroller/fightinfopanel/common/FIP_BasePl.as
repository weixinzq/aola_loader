package mmo.petfightnew.common.fightcontroller.fightinfopanel.common
{
   import flash.display.DisplayObject;
   import flash.system.ApplicationDomain;
   import mmo.common.panel.PanelBase;
   import mmo.petfightnew.common.fightcontroller.fightinfopanel.config.FIP_ResConfig;
   import mmo.play.activity.handler.money.MyJingDouHandler;
   import mmo.play.activity.handler.money.MyXingBiHandler;
   
   public class FIP_BasePl extends PanelBase
   {
      
      protected var _info:FIP_Info = null;
      
      public function FIP_BasePl(param1:String, param2:FIP_Info = null)
      {
         super(FIP_ResConfig.getClassResObject(param1).resPath,FIP_ResConfig.getClassResObject(param1).clsName);
         this._info = param2;
      }
      
      override protected function initComponents() : void
      {
         super.initComponents();
         new MyXingBiHandler(this.res,"txtMyXingbi");
         new MyJingDouHandler(this.res,"txtMyJingdou");
      }
      
      override public function show(param1:ApplicationDomain = null) : void
      {
         super.show(ApplicationDomain.currentDomain);
      }
      
      override protected function addListeners() : void
      {
         super.addListeners();
         this.regClickFunc(/^btn[a-zA-Z0-9_]+/,this.onClickButton,true,null,this);
      }
      
      protected function onClickButton(param1:DisplayObject) : void
      {
      }
      
      override public function dispose() : void
      {
         super.dispose();
      }
   }
}


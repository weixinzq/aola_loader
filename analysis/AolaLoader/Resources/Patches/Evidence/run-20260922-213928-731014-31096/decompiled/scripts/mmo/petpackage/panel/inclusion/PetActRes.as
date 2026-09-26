package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.IDispose;
   import mmo.interfaces.IShowPanel;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.robot.IRobotService;
   import mmo.loader.LoadingSpriteType;
   import mmo.loader.SimpleCustomLoader;
   import mmo.petpackage.controller.event.PetPackageEvent;
   import mmo.petpackage.controller.event.PetPackageEventDispatcher;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol384")]
   public class PetActRes extends MovieClip implements IDispose
   {
      
      public var btnTenderFoot:SimpleButton;
      
      public function PetActRes()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         this.refresh();
         addEventListener(MouseEvent.CLICK,this.onClick);
      }
      
      private function refresh() : void
      {
         var _loc1_:IRobotService = ServiceContainer.getService(IRobotService) as IRobotService;
         var _loc2_:SimpleButton = getChildByName("btnTenderFoot") as SimpleButton;
         TipsManager.getInstance().addTips(_loc2_,"新手神宠大礼");
         _loc2_.visible = _loc1_.getMyDayLife() < 20;
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc3_:String = null;
         var _loc4_:String = null;
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "btnTenderFoot")
         {
            this.close();
            _loc3_ = "activityres/activity131205/unionsummon/unionsummon";
            _loc4_ = "mmo.activity131205.unionsummon.TenderfootPanelProxy";
            this.loadIShowPanel(_loc3_,_loc4_);
         }
      }
      
      private function loadIShowPanel(param1:String, param2:String) : void
      {
         var fileName:String = param1;
         var clsName:String = param2;
         SimpleCustomLoader.loadSingleResource(fileName,clsName,LoadingSpriteType.DIALOG_WITHOUT_CANCLE,"请稍候....",function(param1:IShowPanel):void
         {
            param1.showPanel();
         });
      }
      
      private function close() : void
      {
         PetPackageEventDispatcher.instance.dispatchEvent(new PetPackageEvent(PetPackageEvent.PET_PANEL_CLOSED,{}));
      }
      
      public function dispose() : void
      {
         removeEventListener(MouseEvent.CLICK,this.onClick);
      }
   }
}


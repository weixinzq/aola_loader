package mmo.petpackage.pettips
{
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.interfaces.pet.peticon.PetIconEvent;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.interfaces.pet.pm.services.IPMService;
   
   public class PetTipsPanel extends Sprite
   {
      
      private var viewId:int;
      
      public function PetTipsPanel(param1:int)
      {
         super();
         this.viewId = param1;
         this.initName();
         this.loadIcon();
      }
      
      private function initName() : void
      {
         var _loc1_:IPMService = ServiceContainer.getService(IPMService) as IPMService;
         var _loc2_:String = _loc1_.customData.pmDataMap.getPM(this.viewId).pmName;
         var _loc3_:TextField = this.getChildByName("txtName") as TextField;
         _loc3_.mouseEnabled = false;
         _loc3_.text = _loc2_;
      }
      
      private function loadIcon() : void
      {
         var _loc1_:PetIconContainer = new PetIconContainer(this.viewId,PetIconType.LARGE,false);
         var _loc2_:Sprite = this.getChildByName("iconContainer") as Sprite;
         _loc2_.addChild(_loc1_);
         _loc1_.addEventListener(PetIconEvent.ON_ICON_LOADED,this.onLoadIcon);
         _loc1_.startLoad();
      }
      
      private function onLoadIcon(param1:PetIconEvent) : void
      {
         var _loc2_:PetIconContainer = param1.currentTarget as PetIconContainer;
         _loc2_.removeEventListener(PetIconEvent.ON_ICON_LOADED,this.onLoadIcon);
         DisplayUtil.stop(_loc2_);
         DisplayUtil.scaleDisplay(_loc2_,110,110);
         DisplayUtil.middleDisplay(_loc2_,125,125);
      }
   }
}


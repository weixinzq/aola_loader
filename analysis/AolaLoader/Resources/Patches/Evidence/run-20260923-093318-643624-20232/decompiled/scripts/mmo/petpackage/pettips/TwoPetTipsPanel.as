package mmo.petpackage.pettips
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.peticon.PetIconContainer;
   import mmo.interfaces.pet.peticon.PetIconEvent;
   import mmo.interfaces.pet.peticon.PetIconType;
   import mmo.interfaces.pet.pm.services.IPMService;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol400")]
   public class TwoPetTipsPanel extends Sprite
   {
      
      public var iconContainer0:MovieClip;
      
      public var iconContainer1:MovieClip;
      
      public var txtName0:TextField;
      
      public var txtName1:TextField;
      
      private var viewIdArr:Array;
      
      public function TwoPetTipsPanel(param1:Array)
      {
         super();
         this.viewIdArr = param1;
         this.initName();
         this.loadIcon();
      }
      
      private function initName() : void
      {
         var _loc2_:IPMService = null;
         var _loc3_:String = null;
         var _loc4_:TextField = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.viewIdArr.length)
         {
            _loc2_ = ServiceContainer.getService(IPMService) as IPMService;
            _loc3_ = _loc2_.customData.pmDataMap.getPM(this.viewIdArr[_loc1_]).pmName;
            _loc4_ = this.getChildByName("txtName" + _loc1_.toString()) as TextField;
            _loc4_.mouseEnabled = false;
            _loc4_.text = _loc3_;
            _loc1_++;
         }
      }
      
      private function loadIcon() : void
      {
         var _loc2_:int = 0;
         var _loc3_:PetIconContainer = null;
         var _loc4_:Sprite = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.viewIdArr.length)
         {
            _loc2_ = int(this.viewIdArr[_loc1_]);
            _loc3_ = new PetIconContainer(_loc2_,PetIconType.LARGE,false);
            _loc4_ = this.getChildByName("iconContainer" + _loc1_.toString()) as Sprite;
            _loc4_.addChild(_loc3_);
            _loc3_.addEventListener(PetIconEvent.ON_ICON_LOADED,this.onLoadIcon);
            _loc3_.startLoad();
            _loc1_++;
         }
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


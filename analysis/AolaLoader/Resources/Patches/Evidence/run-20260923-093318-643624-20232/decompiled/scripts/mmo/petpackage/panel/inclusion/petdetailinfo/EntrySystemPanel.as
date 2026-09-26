package mmo.petpackage.panel.inclusion.petdetailinfo
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.play.entrysystem.EntrySystemIconHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol1066")]
   public class EntrySystemPanel extends PetDetailBase
   {
      
      private static const IconWidth:int = 110;
      
      private static const IconHeight:int = 100;
      
      private static const Leading:int = 4;
      
      private static const RowNum:int = 3;
      
      public var containerarea:MovieClip;
      
      private var _iconContainer:Sprite;
      
      private var _pmSvr:IPMService = ServiceContainer.getService(IPMService);
      
      public function EntrySystemPanel()
      {
         super();
      }
      
      override protected function initUI() : void
      {
         var _loc3_:int = 0;
         var _loc4_:Sprite = null;
         this._iconContainer = this.getChildByName("containerarea") as Sprite;
         DisplayUtil.clearChildren(this._iconContainer);
         var _loc1_:Array = this._pmSvr.getOperationPM(this.pdi.raceId).pmData.entrySystemIndexArr;
         var _loc2_:int = 0;
         for each(_loc3_ in _loc1_)
         {
            if(_loc3_ > 0)
            {
               _loc4_ = new Sprite();
               _loc4_.x = _loc2_ % RowNum * (IconWidth + Leading);
               _loc4_.y = Math.floor(_loc2_ / RowNum) * (IconHeight + Leading);
               _loc4_.name = "mcEntrySystem_" + _loc3_;
               this._iconContainer.addChild(_loc4_);
               EntrySystemIconHelper.loadIcon(_loc3_,_loc4_);
               _loc2_++;
            }
         }
      }
      
      override public function dispose() : void
      {
         super.dispose();
      }
   }
}


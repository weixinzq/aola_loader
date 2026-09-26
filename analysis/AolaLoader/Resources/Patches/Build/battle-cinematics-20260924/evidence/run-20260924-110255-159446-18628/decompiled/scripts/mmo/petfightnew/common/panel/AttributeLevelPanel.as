package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.common.DisplayUtil;
   import mmo.interfaces.pet.data.PetBriefInfo;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol2838")]
   public class AttributeLevelPanel extends Sprite
   {
      
      private static const TOTAL_ATTRIBUTE_TYPE:int = 8;
      
      public var spAtt0:MovieClip;
      
      public var spAtt1:MovieClip;
      
      public var spAtt2:MovieClip;
      
      public var spAtt3:MovieClip;
      
      public var spAtt4:MovieClip;
      
      public var spAtt5:MovieClip;
      
      public var spAtt6:MovieClip;
      
      public var spAtt7:MovieClip;
      
      public function AttributeLevelPanel()
      {
         super();
         DisplayUtil.stop(this);
      }
      
      public function setPet(param1:PetBriefInfo) : void
      {
         var _loc6_:Sprite = null;
         var _loc7_:MovieClip = null;
         var _loc8_:MovieClip = null;
         var _loc9_:MovieClip = null;
         var _loc2_:int = 0;
         var _loc3_:Array = param1.attributeLevelArr;
         var _loc4_:int = 0;
         while(_loc4_ < TOTAL_ATTRIBUTE_TYPE)
         {
            _loc6_ = this.getChildByName("spAtt" + _loc2_) as Sprite;
            if(_loc3_[_loc4_] != 0)
            {
               _loc6_.visible = true;
               _loc7_ = _loc6_.getChildByName("mcDes") as MovieClip;
               _loc7_.gotoAndStop(_loc4_ + 1);
               _loc8_ = _loc6_.getChildByName("mcState") as MovieClip;
               _loc8_.gotoAndStop(_loc3_[_loc4_] > 0 ? 1 : 2);
               _loc9_ = _loc8_.getChildByName("mcNum") as MovieClip;
               _loc9_.gotoAndStop(Math.abs(_loc3_[_loc4_]));
               _loc2_++;
            }
            _loc4_++;
         }
         var _loc5_:int = _loc2_;
         while(_loc5_ < TOTAL_ATTRIBUTE_TYPE)
         {
            _loc6_ = this.getChildByName("spAtt" + _loc5_) as Sprite;
            _loc6_.visible = false;
            _loc5_++;
         }
      }
   }
}


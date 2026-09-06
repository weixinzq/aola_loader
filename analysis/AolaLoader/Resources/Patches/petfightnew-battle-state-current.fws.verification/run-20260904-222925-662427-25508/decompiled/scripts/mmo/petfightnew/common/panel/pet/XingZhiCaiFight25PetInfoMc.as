package mmo.petfightnew.common.panel.pet
{
   import flash.display.MovieClip;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.actthings.helper.ActComHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3231")]
   public class XingZhiCaiFight25PetInfoMc extends MovieClip
   {
      
      public var mcColor_0:MovieClip;
      
      public var mcColor_1:MovieClip;
      
      public var mcColor_2:MovieClip;
      
      public var mcColor_3:MovieClip;
      
      public function XingZhiCaiFight25PetInfoMc()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
      }
      
      public function setPet(param1:PlayerBattleInfo) : Boolean
      {
         var _loc7_:String = null;
         var _loc2_:PetBriefInfo = param1.myPets[0];
         var _loc3_:String = _loc2_.status;
         var _loc4_:Array = StatusUtil.parseStatusStr(_loc3_);
         var _loc5_:Array = [];
         var _loc6_:int = 0;
         while(_loc6_ < _loc4_.length)
         {
            _loc7_ = _loc4_[_loc6_];
            if(_loc7_.indexOf("xzc251121") == 0)
            {
               _loc5_ = _loc7_.split("=")[1].split(":");
            }
            _loc6_++;
         }
         this.setMc(_loc5_);
         return _loc5_.length > 0;
      }
      
      private function setMc(param1:Array) : void
      {
         if(param1.length <= 0)
         {
            return;
         }
         this.gotoAndStop(param1.length);
         var _loc2_:int = 0;
         while(_loc2_ < param1.length)
         {
            ActComHelper.setMcFrame(this,"mcColor_" + _loc2_,parseInt(param1[_loc2_]) + 1);
            _loc2_++;
         }
      }
      
      public function dispose() : void
      {
      }
   }
}


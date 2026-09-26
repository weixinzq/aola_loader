package mmo.petfightnew.common.panel.pet
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.actthings.helper.ActComHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol240")]
   public class GQGuiLingXieYiPetInfoMC extends Sprite
   {
      
      private static const maxNum:int = 99999999;
      
      public var mcGuiLingXieYiNum:MovieClip;
      
      private var _mcHuruNum:MovieClip;
      
      private var _startX:Number;
      
      public function GQGuiLingXieYiPetInfoMC()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         this._mcHuruNum = this.getChildByName("mcGuiLingXieYiNum") as MovieClip;
         this._startX = this._mcHuruNum.x;
         this.setNum(0);
      }
      
      public function setPet(param1:PlayerBattleInfo) : Boolean
      {
         var _loc2_:PetBriefInfo = param1.myPets[0];
         var _loc3_:int = int(StatusUtil.getGuiLingXieYiHpArr(_loc2_)[0]);
         this.setNum(_loc3_);
         return _loc3_ > 0;
      }
      
      private function setNum(param1:int) : void
      {
         if(param1 > maxNum)
         {
            param1 = maxNum;
         }
         ActComHelper.setMcNum(this._mcHuruNum,"mcNum_",param1,false);
         var _loc2_:int = 1;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         while(_loc4_ < 20)
         {
            if(param1 <= _loc2_)
            {
               break;
            }
            _loc3_++;
            _loc2_ *= 10;
            _loc4_++;
         }
         this._mcHuruNum.x = this._startX + 10 * _loc3_;
      }
      
      public function dispose() : void
      {
      }
   }
}


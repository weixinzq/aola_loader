package mmo.petfightnew.common.panel.pet
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.text.TextField;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.actthings.helper.ActComHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol286")]
   public class HunDunSumPetInfoMC extends Sprite
   {
      
      private static const maxNum:int = 99999999;
      
      public var mcHuruNum:MovieClip;
      
      private var _txtHurtNum:TextField;
      
      private var _mcHuruNum:MovieClip;
      
      private var _startX:Number;
      
      private var tx:int = 1;
      
      public function HunDunSumPetInfoMC()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         this._mcHuruNum = this.getChildByName("mcHuruNum") as MovieClip;
         this._startX = this._mcHuruNum.x;
         this.setNum(0);
      }
      
      public function setPet(param1:PlayerBattleInfo) : Boolean
      {
         var _loc7_:String = null;
         var _loc2_:PetBriefInfo = param1.myPets[0];
         var _loc3_:String = _loc2_.status;
         var _loc4_:Array = StatusUtil.parseStatusStr(_loc3_);
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         while(_loc6_ < _loc4_.length)
         {
            _loc7_ = _loc4_[_loc6_];
            if(_loc7_.indexOf("hunDunSumDamage") == 0)
            {
               _loc5_ = int(_loc7_.split("_")[1]);
            }
            _loc6_++;
         }
         this.setNum(_loc5_);
         return _loc5_ > 0;
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


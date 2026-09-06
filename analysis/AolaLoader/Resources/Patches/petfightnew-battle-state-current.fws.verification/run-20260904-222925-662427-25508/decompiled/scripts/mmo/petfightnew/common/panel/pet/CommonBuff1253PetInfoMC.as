package mmo.petfightnew.common.panel.pet
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.petfightnew.common.util.StatusUtil;
   import mmo.play.actthings.helper.ActComHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol285")]
   public class CommonBuff1253PetInfoMC extends Sprite
   {
      
      private static const maxNum:int = 99999999;
      
      public var mcCommon1253Num:MovieClip;
      
      private var _mcHuruNum:MovieClip;
      
      private var _startX:Number;
      
      private var _isCBF1450:Boolean = false;
      
      public function CommonBuff1253PetInfoMC()
      {
         super();
         this.init();
      }
      
      private function init() : void
      {
         this._mcHuruNum = this.getChildByName("mcCommon1253Num") as MovieClip;
         this._startX = this._mcHuruNum.x;
         this.setNum(0);
      }
      
      public function setPet(param1:PlayerBattleInfo) : Boolean
      {
         var _loc7_:String = null;
         var _loc8_:Array = null;
         var _loc9_:int = 0;
         this._isCBF1450 = false;
         var _loc2_:PetBriefInfo = param1.myPets[0];
         if(!_loc2_ || _loc2_.curHp <= 0)
         {
            return false;
         }
         var _loc3_:String = _loc2_.status;
         var _loc4_:Array = StatusUtil.parseStatusStr(_loc3_);
         var _loc5_:String = "";
         var _loc6_:int = 0;
         while(_loc6_ < _loc4_.length)
         {
            _loc7_ = _loc4_[_loc6_];
            if(_loc7_.indexOf("cbf_1253") == 0)
            {
               _loc8_ = _loc7_.split("_");
               _loc9_ = 4;
               while(_loc9_ < _loc8_.length)
               {
                  if(parseInt(_loc8_[_loc9_]) > -1)
                  {
                     _loc5_ += _loc8_[_loc9_];
                  }
                  _loc9_++;
               }
               break;
            }
            if(_loc7_.indexOf("cbf_1289") == 0)
            {
               _loc8_ = _loc7_.split("_");
               _loc5_ += _loc8_[3];
               break;
            }
            if(_loc7_.indexOf("cbf_1450") == 0 || _loc7_.indexOf("cbf_1480") == 0)
            {
               this._isCBF1450 = true;
               _loc8_ = _loc7_.split("_");
               _loc5_ += _loc8_[3];
               break;
            }
            if(_loc7_.indexOf("alys250117") == 0 || _loc7_.indexOf("mtyj430027") == 0)
            {
               this._isCBF1450 = true;
               _loc8_ = _loc7_.split("_");
               _loc5_ += _loc8_[1];
               break;
            }
            _loc6_++;
         }
         this.setNum(parseInt(_loc5_));
         return _loc5_.length > 0;
      }
      
      private function setNum(param1:int) : void
      {
         if(this._isCBF1450)
         {
            this._mcHuruNum.gotoAndStop(param1 < 0 ? 1 : 2);
         }
         else
         {
            this._mcHuruNum.gotoAndStop(3);
         }
         var _loc2_:MovieClip = ActComHelper.getChildNode(this._mcHuruNum,"mc") as MovieClip;
         param1 = Math.abs(param1);
         if(param1 > maxNum)
         {
            param1 = maxNum;
         }
         ActComHelper.setMcNum(_loc2_,"mcNum_",param1,false);
         var _loc3_:int = 1;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         while(_loc5_ < 20)
         {
            if(param1 <= _loc3_)
            {
               break;
            }
            _loc4_++;
            _loc3_ *= 10;
            _loc5_++;
         }
         this._mcHuruNum.x = this._startX;
      }
      
      public function dispose() : void
      {
      }
   }
}


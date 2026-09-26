package mmo.petfightnew.common.ui.fetter
{
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.system.ApplicationDomain;
   import mmo.common.DisplayUtil;
   import mmo.common.fetter.FetterTips_Helper;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.data.ActivedFetter;
   
   public class FetterUI extends Sprite
   {
      
      private static const URL:String = "pet/fetter/fetterui";
      
      private static const CLS:String = "mmo.petfightnew.common.ui.fetter.FetterUIView";
      
      private static const MAX_FETTER_ICON_NUM:int = 10;
      
      private static const TOTAL_SIDE:int = 2;
      
      private var _isDisposed:Boolean = false;
      
      private var _view:MovieClip = null;
      
      public function FetterUI()
      {
         super();
         this.startLoadRes();
      }
      
      private function startLoadRes() : void
      {
         ResScheduler.getTempResource(URL,this.onGetView,CLS);
      }
      
      private function onGetView(param1:MovieClip, param2:ApplicationDomain) : void
      {
         if(this._isDisposed)
         {
            return;
         }
         this._view = param1;
         this.init();
      }
      
      private function init() : void
      {
         var _loc1_:MovieClip = null;
         var _loc2_:int = 0;
         while(_loc2_ < TOTAL_SIDE)
         {
            _loc1_ = this._view.getChildByName("mcfetters" + _loc2_) as MovieClip;
            this.setFetterIcon(_loc1_,this.getActivedFettersOfSide(_loc2_));
            _loc2_++;
         }
         this.addChild(this._view);
      }
      
      private function getActivedFettersOfSide(param1:int) : Array
      {
         if(!FightData.instance.myInfo.isLocalIdAndSlotIdSame())
         {
            param1 = TOTAL_SIDE - param1 - 1;
         }
         return FightData.instance.fetterEffect[param1];
      }
      
      private function setFetterIcon(param1:MovieClip, param2:Array) : void
      {
         var _loc4_:MovieClip = null;
         var _loc5_:ActivedFetter = null;
         var _loc6_:int = 0;
         var _loc3_:int = 0;
         while(_loc3_ < MAX_FETTER_ICON_NUM)
         {
            _loc4_ = param1["mcicon" + _loc3_];
            _loc5_ = param2[_loc3_];
            if(_loc5_)
            {
               _loc6_ = int(_loc5_.baseFetter.id);
               _loc4_.gotoAndStop(_loc6_ + 1);
               FetterTips_Helper.addFetterTips(_loc4_,_loc6_,_loc5_.level);
            }
            else
            {
               DisplayUtil.stopAndRemove(_loc4_);
            }
            _loc3_++;
         }
      }
      
      private function seperateActivedFetters(param1:Array) : Array
      {
         var _loc4_:ActivedFetter = null;
         var _loc5_:int = 0;
         var _loc2_:Array = [];
         var _loc3_:int = 0;
         while(_loc3_ < param1.length)
         {
            _loc4_ = param1[_loc3_];
            if(_loc4_.level > 1)
            {
               _loc5_ = 1;
               while(_loc5_ < _loc4_.level)
               {
                  _loc2_.push(new ActivedFetter(_loc4_.baseFetter,_loc5_));
                  _loc5_++;
               }
            }
            _loc2_.push(_loc4_);
            _loc3_++;
         }
         return _loc2_;
      }
      
      public function dispose() : void
      {
         this._isDisposed = true;
         ResScheduler.cancelURL(URL);
      }
   }
}


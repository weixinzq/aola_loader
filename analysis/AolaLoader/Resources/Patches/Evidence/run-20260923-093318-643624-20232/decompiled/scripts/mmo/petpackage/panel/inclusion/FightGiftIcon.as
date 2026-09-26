package mmo.petpackage.panel.inclusion
{
   import flash.display.MovieClip;
   import flash.display.SimpleButton;
   import flash.events.MouseEvent;
   import mmo.common.utils.bit.BitState;
   import mmo.common.utils.panel.modaldialog.ModalDialogManager;
   import mmo.play.actthings.helper.ActComHelper;
   import mmo.play.actthings.helper.ActGoHelper;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol548")]
   public class FightGiftIcon extends MovieClip
   {
      
      public var btngo:SimpleButton;
      
      private const ExtName:String = "HolidayExtension";
      
      private const CmdHead:String = "PG200221";
      
      private var _isGainPetBn:Boolean = false;
      
      public const COMMON_BN_NEED:Array = [10000,40000,80000,120000,180000,200000,220000,250000];
      
      private var _commonBnState:BitState = new BitState(0,this.COMMON_BN_NEED.length);
      
      public function FightGiftIcon()
      {
         super();
         this.initFuns();
      }
      
      private function initFuns() : void
      {
         this.addEventListener(MouseEvent.CLICK,this.onClick);
         this.sendMsg(this.CmdHead + "_panel",this.afterGetInfo);
      }
      
      private function disposeFuns() : void
      {
         this.removeEventListener(MouseEvent.CLICK,this.onClick);
      }
      
      private function sendMsg(param1:String, param2:Function = null, param3:Object = null) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ClassCastException (com.jpexs.decompiler.graph.model.CommaExpressionItem cannot be cast to com.jpexs.decompiler.flash.abc.avm2.model.NewFunctionAVM2Item)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private function onClick(param1:MouseEvent) : void
      {
         var _loc3_:Object = null;
         var _loc2_:String = param1.target.name;
         if(_loc2_ == "btngo")
         {
            _loc3_ = {
               "url":"activityres/activity201231/giftcenterdaily/giftcenterdaily_code",
               "cls":"mmo.activity201231.giftcenterdaily.panel.GCD_MainPl",
               "data":{"tab":11}
            };
            ModalDialogManager.getInstance().clearAll();
            ActGoHelper.goByObj(_loc3_);
         }
      }
      
      private function afterGetInfo(param1:Object) : void
      {
         this._isGainPetBn = param1.gk;
         this._commonBnState.setValue(param1.gf);
         ActComHelper.setVisible(this,"btngo",!this.isGetAll());
      }
      
      private function isGetAll() : Boolean
      {
         var _loc1_:int = 0;
         while(_loc1_ < this.COMMON_BN_NEED.length)
         {
            if(!this._commonBnState.isBitSet(_loc1_))
            {
               return false;
            }
            _loc1_++;
         }
         return this._isGainPetBn;
      }
      
      public function dispose() : void
      {
         this.disposeFuns();
      }
   }
}


package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.events.MouseEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.fight.PetFightEvent;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3595")]
   public class ChangePetIcon extends MovieClip
   {
      
      public function ChangePetIcon()
      {
         super();
         this.gotoAndStop(1);
         this.addEventListener(MouseEvent.CLICK,this.onClickMe);
      }
      
      private function onClickMe(param1:MouseEvent) : void
      {
         var _loc2_:* = this.currentFrame == 1;
         if(_loc2_)
         {
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.CLICK_SWITCH_PET,{}));
         }
      }
      
      override public function gotoAndStop(param1:Object, param2:String = null) : void
      {
         super.gotoAndStop(param1,param2);
         this.changeTips();
      }
      
      private function changeTips() : void
      {
         if(this.currentFrame == 1)
         {
            TipsManager.getInstance().replaceTips(this,"可手动替换背包内其他亚比继续战斗！",0,-30,-20);
         }
         else
         {
            TipsManager.getInstance().removeTips(this);
         }
      }
   }
}


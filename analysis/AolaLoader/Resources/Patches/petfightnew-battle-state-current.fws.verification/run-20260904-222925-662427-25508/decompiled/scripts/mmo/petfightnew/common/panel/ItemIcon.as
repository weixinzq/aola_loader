package mmo.petfightnew.common.panel
{
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import mmo.common.eventdispatcher.CommonEventDispatcher;
   import mmo.common.utils.tips.TipsManager;
   import mmo.interfaces.pet.fight.PetFightEvent;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol3545")]
   public class ItemIcon extends MovieClip
   {
      
      public function ItemIcon()
      {
         super();
         this.addEventListener(MouseEvent.CLICK,this.onClickMe);
         this.addEventListener(Event.REMOVED_FROM_STAGE,this.onRemoveMe);
      }
      
      private function onRemoveMe(param1:Event) : void
      {
         this.removeEventListener(MouseEvent.CLICK,this.onClickMe);
      }
      
      private function onClickMe(param1:MouseEvent) : void
      {
         if(this.currentFrame != 2)
         {
            CommonEventDispatcher.instance.dispatchEvent(new PetFightEvent(PetFightEvent.CLICK_DAO_JU_BTN,{}));
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
            TipsManager.getInstance().replaceTips(this,"可使用背包内道具为亚比回血或解除异常状态！",0,-30,-20);
         }
         else
         {
            TipsManager.getInstance().removeTips(this);
         }
      }
   }
}


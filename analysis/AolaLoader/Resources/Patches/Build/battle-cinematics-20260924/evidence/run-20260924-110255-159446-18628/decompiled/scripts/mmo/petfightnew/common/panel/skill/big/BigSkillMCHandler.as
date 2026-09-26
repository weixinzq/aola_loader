package mmo.petfightnew.common.panel.skill.big
{
   import flash.events.MouseEvent;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.pm.services.IPMService;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.component.CachedClip;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class BigSkillMCHandler
   {
      
      protected var _mcChangeView:CachedClip;
      
      protected var _pmService:IPMService = ServicePool.instance.getService(IPMService);
      
      protected const EVENT_FUNC_MAP:Object = {};
      
      public function BigSkillMCHandler()
      {
         super();
         this.initActionMap();
      }
      
      private function initActionMap() : void
      {
         this.EVENT_FUNC_MAP[BigSkillMCEvent.UPDATE] = this.update;
         this.EVENT_FUNC_MAP[BigSkillMCEvent.CLICK] = this.onClicked;
         this.EVENT_FUNC_MAP[BigSkillMCEvent.ROLL_OVER] = this.onMouseRollOver;
         this.EVENT_FUNC_MAP[BigSkillMCEvent.ROLL_OUT] = this.onMouseRollOut;
      }
      
      public function initView(param1:CachedClip) : void
      {
         this._mcChangeView = param1;
      }
      
      public function event(param1:String, param2:* = null) : Boolean
      {
         var _loc3_:Function = this.EVENT_FUNC_MAP[param1];
         if(this.care())
         {
            if(param2)
            {
               _loc3_.apply(null,[param2]);
            }
            else
            {
               _loc3_.apply(null);
            }
            return true;
         }
         return false;
      }
      
      public function update() : void
      {
      }
      
      protected function getSkillPowerDesc(param1:int) : String
      {
         if(param1 > 0)
         {
            return param1.toString();
         }
         return "未知";
      }
      
      protected function setMouseChildren(param1:Boolean) : void
      {
         if(this._mcChangeView.curClip)
         {
            this._mcChangeView.curClip.mouseChildren = param1;
            this._mcChangeView.curClip.buttonMode = param1;
         }
      }
      
      protected function getOperatingPetInfo() : PetBriefInfo
      {
         return FightData.instance.getOperatingPet();
      }
      
      public function onMouseRollOver(param1:MouseEvent) : void
      {
      }
      
      public function onMouseRollOut() : void
      {
      }
      
      public function onClicked(param1:MouseEvent) : void
      {
      }
      
      protected function care() : Boolean
      {
         return false;
      }
      
      public function dispose() : void
      {
      }
   }
}


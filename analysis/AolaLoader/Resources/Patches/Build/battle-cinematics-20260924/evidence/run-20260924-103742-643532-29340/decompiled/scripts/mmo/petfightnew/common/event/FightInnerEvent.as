package mmo.petfightnew.common.event
{
   import flash.events.Event;
   
   public class FightInnerEvent extends Event
   {
      
      public static const ON_MOUSE_OVER_PET:String = "mouse_over_mcpetcontainer";
      
      public static const ON_MOUSE_OUT_PET:String = "mouse_out_mcpetcontainer";
      
      public static const ON_PET_APPEAR:String = "on_pet_appear";
      
      public static const ON_DEGENERATOR_XIAN_APPEAR:String = "my_degeneratorxian_pet_appear";
      
      public static const CHANGE_USING_SKILL:String = "changePetUsingSkill";
      
      public static const SELECT_SWITCHING_PET:String = "selectSwitchingPet";
      
      private var _params:Object;
      
      public function FightInnerEvent(param1:String, param2:Object)
      {
         super(param1);
         this._params = param2;
      }
      
      public function get params() : Object
      {
         return this._params;
      }
   }
}


package mmo.petfightnew.common.config
{
   public class FightActUIConfig
   {
      
      public function FightActUIConfig()
      {
         super();
      }
      
      public static function getActUIUrl(param1:int) : String
      {
         return "pet/fightactui/fightactui_" + param1;
      }
      
      public static function getActUICls(param1:int) : String
      {
         return "mmo.fightactui.FightActUI_" + param1;
      }
      
      public static function checkHaveUI(param1:int) : Boolean
      {
         return param1 > 0;
      }
   }
}


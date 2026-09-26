package mmo.petfightnew.common.config
{
   import mmo.interfaces.pet.fight.IPetFightConfig;
   import mmo.petfightnew.common.manager.ServicePool;
   
   public class PMTalkConfig
   {
      
      private static var _talkMap:Object;
      
      private static var _haveInited:Boolean = false;
      
      public function PMTalkConfig()
      {
         super();
      }
      
      public static function get talkMap() : Object
      {
         if(!_haveInited)
         {
            init();
            _haveInited = true;
         }
         return _talkMap;
      }
      
      private static function init() : void
      {
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:Object = null;
         var _loc1_:Object = {};
         var _loc2_:int = 0;
         while(_loc2_ < 30)
         {
            _loc4_ = _loc2_ * 5 + 1;
            _loc5_ = _loc2_ % 3;
            _loc6_ = {
               "pathName":"bossfightmovie/boss_xhtz" + _loc5_,
               "className":"mmo.petfight.boss.xhtz" + _loc5_
            };
            _loc1_[_loc4_] = _loc6_;
            _loc2_++;
         }
         var _loc3_:IPetFightConfig = ServicePool.instance.getService("PetFightService");
         _talkMap = _loc3_.PMTalkConfigTalkMap;
         _talkMap[12273] = _loc1_;
         _talkMap[12274] = _loc1_;
      }
   }
}


package mmo.petfightnew.common.manager
{
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.loader.scheduler.ResDomain;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.helper.LoadFileHelper;
   import mmo.play.petfight.common.config.FightResConfig;
   import mmo.play.petfight.common.config.SkillMap;
   
   public class PreloadListManager
   {
      
      private static var _instance:PreloadListManager;
      
      private var _resDomain:ResDomain;
      
      private var _historyEffectIds:Array = [];
      
      private var _historyLoadPet:Array = [];
      
      public function PreloadListManager()
      {
         super();
      }
      
      public static function get instance() : PreloadListManager
      {
         if(_instance == null)
         {
            _instance = new PreloadListManager();
         }
         return _instance;
      }
      
      public function preloadResOfPet(param1:PetBriefInfo, param2:int) : void
      {
         this.preloadEffectOfPet(param1);
         var _loc3_:int = int(PetAssetsMap.getPetFlaId(param1.viewId));
         var _loc4_:int = FightData.instance.getFaceIdByLocalId(param2);
         this.preloadComplementaryMovieFile(_loc3_,_loc4_);
      }
      
      private function preloadEffectOfPet(param1:PetBriefInfo) : void
      {
         var _loc2_:SkillInfo = null;
         var _loc3_:int = 0;
         for each(_loc2_ in param1.skills)
         {
            _loc3_ = int(SkillMap.instance.getEffectId(param1.raceId,_loc2_.id));
            this.preloadEffect(_loc3_);
         }
      }
      
      public function preloadComplementaryMovieFile(param1:int, param2:int) : void
      {
         var _loc6_:String = null;
         if(!FightResConfig.isComplementaryPetMovie(param1,param2))
         {
            return;
         }
         var _loc3_:String = param1 + "_" + param2;
         if(this._historyLoadPet.indexOf(_loc3_) >= 0)
         {
            return;
         }
         this._historyLoadPet.push(_loc3_);
         var _loc4_:int = int(FightResConfig.FILE_NUM_OF_COMPLEMENTARY_PET_MOVIE);
         var _loc5_:int = 1;
         while(_loc5_ < _loc4_)
         {
            _loc6_ = FightResConfig.getFilePathOfComplementaryPetMovie(param1,param2,_loc5_);
            this.preloadSingleFile(_loc6_,FightData.instance.getPetViewDomain());
            _loc5_++;
         }
      }
      
      public function preloadEffect(param1:int) : void
      {
         if(this._historyEffectIds.indexOf(param1) >= 0)
         {
            return;
         }
         this._historyEffectIds.push(param1);
         var _loc2_:String = FightResConfig.getEffectMovieURL(param1);
         this.preloadSingleFile(_loc2_);
      }
      
      private function preloadSingleFile(param1:String, param2:ResDomain = null) : void
      {
         if(param2)
         {
            LoadFileHelper.preloadSingleFile(param1,param2);
         }
         else
         {
            LoadFileHelper.preloadSingleFile(param1,this.domain);
         }
      }
      
      private function get domain() : ResDomain
      {
         if(this._resDomain == null)
         {
            this._resDomain = new ResDomain(FightData.instance.applicationDomain);
         }
         return this._resDomain;
      }
      
      public function dispose() : void
      {
         this._resDomain = null;
         this._historyEffectIds = null;
         _instance = null;
      }
   }
}


package mmo.petfightnew.common.util
{
   import flash.media.Sound;
   import mmo.common.sound.SoundPlayer;
   import mmo.interfaces.pet.data.PetAssetsMap;
   import mmo.interfaces.pet.data.PetBriefInfo;
   import mmo.interfaces.pet.data.PlayerBattleInfo;
   import mmo.interfaces.pet.data.SkillInfo;
   import mmo.interfaces.pet.fightmusic.IFightMusic;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.FightData;
   import mmo.petfightnew.common.bossmovie.BossMovieConfig;
   import mmo.petfightnew.common.config.FightActUIConfig;
   import mmo.petfightnew.common.fightcontroller.AoYiMovieHelper;
   import mmo.petfightnew.common.manager.PreloadListManager;
   import mmo.petfightnew.common.pet.PetSoundHelper;
   import mmo.play.petfight.common.config.FightResConfig;
   import mmo.play.petfight.common.config.SkillMap;
   import mmo.play.scene.SceneManager;
   
   public class PreLoadAssetsUtil
   {
      
      private static var _instance:PreLoadAssetsUtil;
      
      private var loadQueue:Array = [];
      
      private var _isLoading:Boolean = false;
      
      private var callBack:Function;
      
      private var _progress:Number = 0;
      
      private var loadedNum:int;
      
      private var total:int;
      
      private var ipetmusic:IFightMusic;
      
      private var bossMcConfig:Array;
      
      private var soundplayer:SoundPlayer;
      
      private var _preloadQueue:Array;
      
      public function PreLoadAssetsUtil()
      {
         super();
      }
      
      public static function get instance() : PreLoadAssetsUtil
      {
         if(_instance == null)
         {
            _instance = new PreLoadAssetsUtil();
         }
         return _instance;
      }
      
      public function get isLoading() : Boolean
      {
         return this._isLoading;
      }
      
      public function get progress() : Number
      {
         this._progress = this.loadedNum / this.total;
         return this._progress;
      }
      
      public function loadAssets(param1:Array, param2:Function = null) : void
      {
         this.callBack = param2;
         this._isLoading = true;
         this.initLoadList(param1);
         this.loadNext();
         this.preloadRes();
      }
      
      private function initLoadList(param1:Array) : void
      {
         this.loadQueue = [];
         this._preloadQueue = FightResConfig.PRELOAD_RES_LIST.concat();
         this.initSkillAndPet(param1);
         this.initBossMovie();
         this.initBackGrounds();
         this.initFightRes();
         this.initNpcIcon();
         this.initFightActUI();
         this.loadedNum = 0;
         this.total = this.loadQueue.length;
      }
      
      private function initAsyncRes() : void
      {
         this.loadQueue.push("pet/fightasyncres/waitbgmovie/movie");
      }
      
      private function loadNext() : void
      {
         if(this.loadQueue == null)
         {
            return;
         }
         if(this.loadQueue.length == 0)
         {
            this.onLoadCompleted();
            return;
         }
         var _loc1_:String = this.loadQueue.shift();
         ResScheduler.getResource(_loc1_,this.onLoadEnd,"",this.onLoadEnd,null,ResPriority.NORMAL,false,FightData.instance.applicationDomain);
      }
      
      private function preloadRes() : void
      {
         ResScheduler.preLoad(this._preloadQueue,new ResDomain(FightData.instance.applicationDomain));
      }
      
      private function onLoadEnd(param1:* = null) : void
      {
         ++this.loadedNum;
         this.loadNext();
      }
      
      private function initBackGrounds() : void
      {
         var _loc1_:String = SceneManager.getInstance().loadedSceneInfo.sceneName;
         var _loc2_:String = GetBackgroundUtil.getFileName(_loc1_);
         this.loadQueue.push(_loc2_);
      }
      
      private function initBossMovie() : void
      {
         var _loc2_:PlayerBattleInfo = null;
         var _loc1_:int = 0;
         while(_loc1_ < FightData.instance.opponents.length)
         {
            _loc2_ = FightData.instance.opponents[_loc1_];
            this.bossMcConfig = BossMovieConfig.getConfig(_loc2_.myPets[0].raceId);
            if(this.bossMcConfig != null)
            {
               this.loadQueue.push(this.bossMcConfig[0].file);
            }
            _loc1_++;
         }
      }
      
      private function initSkillAndPet(param1:Array) : void
      {
         var _loc3_:PlayerBattleInfo = null;
         var _loc4_:SkillInfo = null;
         var _loc5_:int = 0;
         var _loc6_:PetBriefInfo = null;
         var _loc7_:int = 0;
         var _loc8_:String = null;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc11_:String = null;
         PreloadListManager.instance.preloadEffect(SkillMap.XINGHUI_SKILL_SUPER_SPIRIT_EFFECT_ID);
         var _loc2_:Boolean = false;
         for each(_loc3_ in param1)
         {
            for each(_loc4_ in _loc3_.myPets[0].skills)
            {
               _loc7_ = int(SkillMap.instance.getEffectId(0,_loc4_.id));
               if(SkillMap.instance.isBitmapSkillEffect(_loc7_))
               {
                  PreloadListManager.instance.preloadEffect(_loc7_);
               }
               else
               {
                  _loc8_ = FightResConfig.getVectorEffectMovieURL(_loc7_);
                  this.loadQueue.push(_loc8_);
               }
            }
            _loc5_ = FightData.instance.getFaceIdByLocalId(_loc3_.locaId);
            for each(_loc6_ in _loc3_.myPets)
            {
               _loc9_ = int(PetAssetsMap.getPetFlaId(_loc6_.viewId));
               _loc10_ = FightData.instance.getPetMovieStrategyType(_loc9_);
               _loc11_ = FightResConfig.getPetMainFilePath(_loc10_,_loc9_,_loc5_);
               this.loadQueue.push(_loc11_);
               if(PetBriefInfo(_loc6_).isGetAoYiSkill)
               {
                  _loc2_ = true;
               }
               PetSoundHelper.tryPreLoadPetSound(_loc9_);
               PreloadListManager.instance.preloadComplementaryMovieFile(_loc9_,_loc5_);
            }
         }
         if(_loc2_)
         {
            AoYiMovieHelper.preLoadBaseMovie();
         }
      }
      
      private function initFightRes() : void
      {
         this.loadQueue.push("pet/petfightnew_res");
         this.loadQueue.push("pet/petfightnew_res1");
         this.loadQueue.push("pet/petfightnew_skillwindword");
         this.loadQueue.push("pet/petfightnew_startmv");
         this.loadQueue.push("pet/petfightnew_gqresource");
         this.loadQueue.push("pet/petfightnew_xhresource");
      }
      
      private function initNpcIcon() : void
      {
         this.loadQueue.push("pet/petfightnpcicon");
      }
      
      private function initFightActUI() : void
      {
         var _loc1_:int = FightData.instance.fightActId;
         if(!FightActUIConfig.checkHaveUI(_loc1_))
         {
            return;
         }
         this.loadQueue.push(FightActUIConfig.getActUIUrl(_loc1_));
      }
      
      private function onLoadCompleted() : void
      {
         this._isLoading = false;
         if(this.callBack != null)
         {
            this.callBack.apply();
         }
      }
      
      private function playSound() : void
      {
         var _loc1_:Sound = null;
         _loc1_ = this.ipetmusic.getMusicByName({"other":"x7011"});
         this.soundplayer = new SoundPlayer(_loc1_);
         this.soundplayer.play(true,3);
      }
      
      public function dispose() : void
      {
         this._isLoading = false;
         this.loadQueue = null;
         this._preloadQueue = null;
         _instance = null;
      }
   }
}


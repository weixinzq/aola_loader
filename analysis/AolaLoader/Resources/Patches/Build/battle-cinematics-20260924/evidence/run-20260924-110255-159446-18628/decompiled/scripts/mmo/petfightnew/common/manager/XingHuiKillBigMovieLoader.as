package mmo.petfightnew.common.manager
{
   import com.adobe.utils.StringUtil;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.MovieClip;
   import flash.media.Sound;
   import flash.system.ApplicationDomain;
   import mmo.common.bitmapmovie.BitmapMovieClip;
   import mmo.common.bitmapmovie.BitmapMovieClipParser;
   import mmo.interfaces.ServiceContainer;
   import mmo.interfaces.option.IGameOptionService;
   import mmo.loader.common.datastructures.ResourceObject;
   import mmo.loader.scheduler.ResDomain;
   import mmo.loader.scheduler.ResParams;
   import mmo.loader.scheduler.ResPriority;
   import mmo.loader.scheduler.ResScheduler;
   import mmo.petfightnew.common.helper.LoadFileHelper;
   import mmo.play.petfight.common.config.FightResConfig;
   import mmo.play.petfight.common.config.XingHuiKillBigConfig;
   
   public class XingHuiKillBigMovieLoader
   {
      
      private static var _gameOptionSvr:IGameOptionService = ServiceContainer.getService(IGameOptionService);
      
      private var _isDisposed:Boolean = false;
      
      private var _domain:ResDomain;
      
      private var _movieId:int;
      
      private var _faceId:int;
      
      private var _onLoaded:Function;
      
      public function XingHuiKillBigMovieLoader(param1:ApplicationDomain)
      {
         super();
         this._domain = new ResDomain(param1);
      }
      
      private static function preloadBitmapMovieFile(param1:Number, param2:int, param3:ResDomain) : void
      {
         var _loc6_:String = null;
         var _loc4_:int = int(FightResConfig.FILE_NUM_OF_BITMAP_XINGHUI_KILL_MOVIE);
         var _loc5_:int = param2;
         while(_loc5_ < _loc4_)
         {
            _loc6_ = FightResConfig.getBitmapXingHuiKillBigMovieURL(param1,_loc5_);
            LoadFileHelper.preloadSingleFile(_loc6_,param3);
            _loc5_++;
         }
      }
      
      public static function preloadCommonMovieFile(param1:int, param2:ResDomain) : void
      {
         var _loc3_:String = FightResConfig.getXingHuiKillBigCommonMovieRes(param1).resPath;
         LoadFileHelper.preloadSingleFile(_loc3_,param2);
         var _loc4_:String = FightResConfig.getXingHuiKillBigCommonMovieSkinRes(param1).resPath;
         LoadFileHelper.preloadSingleFile(_loc4_,param2);
      }
      
      public static function preload(param1:int, param2:ResDomain) : void
      {
         var _loc3_:String = null;
         if(XingHuiKillBigConfig.isCommonMovie(param1))
         {
            XingHuiKillBigMovieLoader.preloadCommonMovieFile(param1,param2);
         }
         else if(FightResConfig.isBitmapXingHuiKillMovie(param1))
         {
            XingHuiKillBigMovieLoader.preloadBitmapMovieFile(param1,0,param2);
         }
         else
         {
            _loc3_ = FightResConfig.getVectorXingHuiKillBigMovieURL(param1);
            LoadFileHelper.preloadSingleFile(_loc3_,param2);
         }
      }
      
      public static function playMusic(param1:int, param2:Boolean, param3:String, param4:ApplicationDomain) : void
      {
         /*
          * Decompilation error
          * Code may be obfuscated
          * Tip: You can try enabling "Deobfuscate code" option in Settings
          * Error type: ArrayIndexOutOfBoundsException (null)
          */
         throw new flash.errors.IllegalOperationError("Not decompiled due to error");
      }
      
      private static function getSound(param1:int, param2:Boolean, param3:ApplicationDomain) : Sound
      {
         var _loc4_:* = null;
         if(param2)
         {
            _loc4_ = "mmo.petfightnew.XingHuiKillBigMovie" + param1 + "_Sound";
         }
         else
         {
            _loc4_ = "mmo.petfightnew.XingHuiSuperSpiritKillMovie" + param1 + "_Sound";
         }
         if(!param3.hasDefinition(_loc4_))
         {
            return null;
         }
         var _loc5_:Class = param3.getDefinition(_loc4_) as Class;
         if(_loc5_ == null)
         {
            return null;
         }
         return new _loc5_() as Sound;
      }
      
      public function init(param1:ApplicationDomain) : void
      {
         this._domain = new ResDomain(param1);
      }
      
      public function loadMovie(param1:int, param2:int, param3:Function) : void
      {
         this._movieId = param1;
         this._faceId = param2;
         this._onLoaded = param3;
         if(FightResConfig.ExcludeIds.indexOf(param1) != -1)
         {
            this.applyLoaded(null);
         }
         else if(Boolean(_gameOptionSvr.isAllFightSkillEffect) || Boolean(XingHuiKillBigConfig.isNotPlayAllEffectMv(param1)))
         {
            if(XingHuiKillBigConfig.isCommonMovie(param1))
            {
               this.loadCommonMovie(param1);
            }
            else if(FightResConfig.isBitmapXingHuiKillMovie(param1))
            {
               this.loadBitmapMovie();
            }
            else
            {
               this.loadVectorMovie();
            }
         }
         else
         {
            this.applyLoaded(null);
         }
      }
      
      private function loadCommonMovie(param1:int) : void
      {
         var raceId:int = param1;
         var res:ResourceObject = FightResConfig.getXingHuiKillBigCommonMovieRes(raceId);
         this.loadRes(res.resPath,res.clsName,function(param1:MovieClip):*
         {
            createCommonMovie(param1,raceId);
         });
      }
      
      private function createCommonMovie(param1:MovieClip, param2:int) : void
      {
         var skinRes:ResourceObject = null;
         var movie:MovieClip = param1;
         var raceId:int = param2;
         movie.gotoAndStop(1);
         skinRes = FightResConfig.getXingHuiKillBigCommonMovieSkinRes(raceId);
         this.loadRes(skinRes.resPath,"",function():*
         {
            var _loc1_:Class = _domain.applicationDomain.getDefinition(skinRes.clsName) as Class;
            var _loc2_:BitmapData = new _loc1_();
            var _loc3_:Bitmap = new Bitmap(_loc2_,"auto",true);
            var _loc4_:MovieClip = movie.getChildByName("mcPet") as MovieClip;
            var _loc5_:MovieClip = _loc4_.getChildByName("mcLocation") as MovieClip;
            _loc3_.x = _loc5_.x;
            _loc3_.y = _loc5_.y;
            _loc4_.addChild(_loc3_);
            applyLoaded(movie);
         });
      }
      
      private function loadRes(param1:String, param2:String, param3:Function) : void
      {
         var url:String = param1;
         var cls:String = param2;
         var onLoadSuc:Function = param3;
         ResScheduler.getRes(ResParams.createTempByDomain(url,function(param1:*, param2:*):*
         {
            if(StringUtil.isNullOrEmpty(cls))
            {
               onLoadSuc.apply();
            }
            else
            {
               onLoadSuc.apply(null,[param1]);
            }
         },this._domain,cls,ResPriority.NORMAL,function():*
         {
            applyLoaded(null);
         }));
      }
      
      private function loadVectorMovie() : void
      {
         var url:String = FightResConfig.getVectorXingHuiKillBigMovieURL(this._movieId);
         var cls:String = FightResConfig.getVectorXingHuiKillBigMovieClsName(this._movieId,this._faceId);
         ResScheduler.getRes(ResParams.createTempByDomain(url,function(param1:MovieClip, param2:*):*
         {
            applyLoaded(param1);
         },this._domain,cls,ResPriority.NORMAL,function():*
         {
            applyLoaded(null);
         }));
      }
      
      private function loadBitmapMovie() : void
      {
         var url:String = FightResConfig.getBitmapXingHuiKillBigMovieURL(this._movieId,0);
         ResScheduler.getRes(ResParams.createTempByDomain(url,function(param1:*):*
         {
            parseBitmapMovie();
         },this._domain,"",ResPriority.NORMAL,function():*
         {
            applyLoaded(null);
         }));
         preloadBitmapMovieFile(this._movieId,1,this._domain);
      }
      
      private function parseBitmapMovie() : void
      {
         var _loc1_:String = FightResConfig.getBitmapXingHuiKillBigMovieConfigClsName(this._movieId);
         var _loc2_:String = BitmapMovieClipParser.getConfigData(_loc1_,this._domain.applicationDomain);
         if(StringUtil.isNullOrEmpty(_loc2_))
         {
            this.applyLoaded(null);
            return;
         }
         var _loc3_:Array = BitmapMovieClipParser.parseConfig(_loc2_);
         var _loc4_:String = FightResConfig.getBitmapXingHuiKillBigMovieBitmapClsNamePrefix(this._movieId);
         var _loc5_:BitmapMovieClip = new BitmapMovieClip(_loc3_,_loc4_,this._domain.applicationDomain);
         this.applyLoaded(_loc5_);
      }
      
      private function applyLoaded(param1:MovieClip) : void
      {
         if(this._isDisposed)
         {
            return;
         }
         this.loadJumpTipsOnMovie(param1);
      }
      
      private function loadJumpTipsOnMovie(param1:MovieClip) : void
      {
         var movie:MovieClip = param1;
         var url:String = FightResConfig.getGQKillBigJumpTipsRes().resPath;
         var cls:String = FightResConfig.getGQKillBigJumpTipsRes().clsName;
         ResScheduler.getRes(ResParams.createTempByDomain(url,function(param1:MovieClip, param2:*):*
         {
            _onLoaded.apply(null,[movie,param1]);
         },this._domain,cls,ResPriority.NORMAL,function():*
         {
            _onLoaded.apply(null,[movie]);
         }));
      }
   }
}


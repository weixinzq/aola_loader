package mmo.petfightnew.common.pet
{
   import com.adobe.utils.StringUtil;
   import flash.display.MovieClip;
   import flash.utils.ByteArray;
   import mmo.common.bitmapmovie.BitmapMovieClip;
   import mmo.common.bitmapmovie.BitmapMovieClipParser;
   import mmo.petfightnew.common.FightData;
   import mmo.play.petfight.common.config.FightResConfig;
   
   public class BitmapPetMovieStrategy extends PetMovieStrategyBase
   {
      
      private static const BITMAP_DATA_CLS_NAME_PREFIX:String = "mmo.petfight.bitmap.pet%1_%2_%3";
      
      private var _config:Object;
      
      public function BitmapPetMovieStrategy(param1:int, param2:int)
      {
         super(param1,param2);
      }
      
      override protected function getTargetPetClsName() : String
      {
         return FightResConfig.getPetBitmapMovieConfigClsName(this._raceId,this._face);
      }
      
      private function initConfig() : void
      {
         var _loc1_:String = this.getTargetPetClsName();
         if(!this.haveDefinitionInFightDomain(_loc1_))
         {
            this._useDefault = true;
            _loc1_ = FightResConfig.getPetBitmapMovieConfigClsName(FightResConfig.DEFAULT_PET_ID,this._face);
         }
         else if(this.isHasRacePng(_loc1_) == false)
         {
            this._useDefault = true;
            _loc1_ = FightResConfig.getPetBitmapMovieConfigClsName(FightResConfig.DEFAULT_PET_ID,this._face);
         }
         this.parseConfig(_loc1_);
      }
      
      override protected function onResPrepared() : void
      {
         this.initConfig();
         super.onResPrepared();
      }
      
      private function parseConfig(param1:String) : void
      {
         var _loc2_:Class = null;
         var _loc3_:MovieClip = null;
         var _loc4_:Class = null;
         var _loc5_:ByteArray = null;
         var _loc6_:String = null;
         var _loc7_:Array = null;
         var _loc8_:String = null;
         var _loc9_:Array = null;
         var _loc10_:String = null;
         var _loc11_:String = null;
         try
         {
            this._config = {};
            _loc2_ = FightData.instance.getPetViewDomain().applicationDomain.getDefinition(param1) as Class;
            _loc3_ = new _loc2_();
            _loc4_ = _loc3_["MovieConfig"] as Class;
            _loc5_ = new _loc4_();
            _loc6_ = _loc5_.readUTFBytes(_loc5_.bytesAvailable);
            _loc7_ = _loc6_.split("#");
            for each(_loc8_ in _loc7_)
            {
               if(_loc8_.indexOf(":") >= 0)
               {
                  _loc9_ = _loc8_.split(":");
                  _loc10_ = _loc9_[0];
                  if(_loc10_.indexOf("$") >= 0)
                  {
                     _loc11_ = _loc10_.split("$")[1];
                  }
                  else
                  {
                     _loc11_ = _loc10_;
                  }
                  this._config[_loc11_] = BitmapMovieClipParser.parseConfig(_loc9_[1]);
               }
            }
         }
         catch(e:*)
         {
         }
      }
      
      override public function getActionMovie(param1:int) : MovieClip
      {
         var _loc2_:MovieClip = this.getMovieCache(param1);
         if(_loc2_ == null)
         {
            _loc2_ = this.getNewActionMovie(param1);
         }
         return _loc2_;
      }
      
      private function getNewActionMovie(param1:int) : BitmapMovieClip
      {
         var _loc6_:Number = NaN;
         var _loc2_:int = this.getRealActFrame(param1);
         if(_loc2_ == -1)
         {
            return null;
         }
         var _loc3_:String = StringUtil.format(BITMAP_DATA_CLS_NAME_PREFIX,this.getRealViewId(),this._face,_loc2_);
         var _loc4_:Array = this._config[_loc2_ + ""];
         var _loc5_:BitmapMovieClip = new BitmapMovieClip(_loc4_,_loc3_,FightData.instance.getPetViewDomain().applicationDomain,false);
         if(FightResConfig.isSpinePetMovie(this._raceId))
         {
            _loc6_ = FightData.instance.getPetScale(this._raceId);
            _loc5_.scaleX = _loc5_.scaleY = _loc6_;
         }
         this.cacheMovie(param1,_loc5_);
         return _loc5_;
      }
      
      private function getRealViewId() : int
      {
         if(this._useDefault)
         {
            return FightResConfig.DEFAULT_PET_ID;
         }
         return this._raceId;
      }
      
      private function getRealActFrame(param1:int) : int
      {
         var _loc5_:int = 0;
         var _loc2_:int = PetActionFrame.getActionIndex(param1);
         if(_loc2_ == -1)
         {
            return -1;
         }
         var _loc3_:Array = PetActionFrame.ACTION_PRIORITY[_loc2_];
         var _loc4_:int = 0;
         while(_loc4_ < _loc3_.length)
         {
            _loc5_ = int(_loc3_[_loc4_]);
            if(this._config.hasOwnProperty(_loc5_ + ""))
            {
               return _loc5_;
            }
            _loc4_++;
         }
         return -1;
      }
      
      override public function dispose() : void
      {
         var _loc1_:* = undefined;
         var _loc2_:BitmapMovieClip = null;
         for(_loc1_ in this._movieCache)
         {
            _loc2_ = this._movieCache[_loc1_];
            _loc2_.dispose();
         }
         this._movieCache = null;
      }
      
      public function isHasRacePng(param1:String) : Boolean
      {
         var _loc2_:Class = FightData.instance.getPetViewDomain().applicationDomain.getDefinition(param1) as Class;
         if(!_loc2_)
         {
            return false;
         }
         var _loc3_:MovieClip = new _loc2_();
         if(!_loc3_)
         {
            return false;
         }
         var _loc4_:Class = _loc3_["MovieConfig"] as Class;
         if(!_loc4_)
         {
            return false;
         }
         var _loc5_:ByteArray = new _loc4_();
         if(!_loc5_)
         {
            return false;
         }
         var _loc6_:String = _loc5_.readUTFBytes(_loc5_.bytesAvailable);
         return (Boolean(_loc6_)) && _loc6_ != "";
      }
   }
}


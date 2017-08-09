(defpackage :cl-sound-ffmpeg
  (:use :cl :cffi :fuktard))

(in-package :cl-sound-ffmpeg)

(eval-always
 (progn
   (defparameter *something* #.(or *compile-file-truename* *load-truename*))
   (defparameter ourdir
     (make-pathname :host (pathname-host *something*)
		    :directory (pathname-directory *something*)))

   (progno (defparameter *dylib* (namestring (merge-pathnames "csrc/libprog" ourdir)))
	   (etouq
	    `(define-foreign-library cl-sound-ffmpeg
	       (t (:default ,*dylib*)))))))

;;(use-foreign-library cl-sound-ffmpeg)


(progn
  (define-foreign-library libavutil
    (t (:default "libavutil")))
  (use-foreign-library libavutil)
  (define-foreign-library libavcodec
    (t (:default "libavcodec")))
  (use-foreign-library libavcodec)
  (define-foreign-library libavformat
    (t (:default "libavformat")))
  (use-foreign-library libavformat)
  (define-foreign-library libswresample
    (t (:default "libswresample")))
  (use-foreign-library libswresample))


;;;int decode_audio_file(const char* path, const int sample_rate, double** data, int* size)

(progno
 (defcfun "decode_audio_file" :int
   (path :string)
   (sample-rate :int)
   (data :pointer)
   (size :pointer))

 (defun get-sound-buff ()
   (let ((adubs nil)
	 (aans nil)
	 (asize -3))
     (cffi:with-foreign-object (data-pointer :pointer)
       (cffi:with-foreign-object (an-int :int)
	 (setf aans
	       (decode-audio-file
		(case 6
		  (0 "/home/terminal256/src/symmetrical-umbrella/sandbox/res/resources/sound3/damage/hit3.ogg")
		  (1 "/home/terminal256/src/symmetrical-umbrella/sandbox/res/resources/streaming/cat.ogg")
		  (2 "/home/terminal256/src/symmetrical-umbrella/sandbox/res/resources/sound3/portal/portal.ogg")
		  (3 "/home/imac/quicklisp/local-projects/symmetrical-umbrella/sandbox/res/resources/sound3/ambient/weather/rain4.ogg")
		  (4 "/home/imac/Music/6PQv-Adele - Hello.mp3")
		  (5 "/home/imac/Music/Louis The Child ft. K.Flay - It's Strange [Premiere] (FIFA 16 Soundtrack) -  128kbps.mp3")
		  (6 "/home/imac/Music/Birdy_-_Keeping_Your_Head_Up_Official.mp3"))
		44100
		data-pointer
		an-int))
	 (setf adubs (cffi:mem-ref data-pointer :pointer))
	 (setf asize (cffi:mem-ref an-int :int))))
     (values adubs asize aans))))

(progno
 (defparameter dubs nil)
 (defparameter size nil)
 (defparameter ans nil)


 (defun test ()
   (reset)
   (setf (values dubs size ans)
	 (get-sound-buff))
   )

 (defun reset ()
   (when dubs
     
     (foreign-free dubs)
     (setf dubs nil)))

 (defun alut-hello-world ()
   (alc:with-device (device)
     (alc:with-context (context device)
       (alc:make-context-current context)
       (al:with-source (source)
	 (al:with-buffer (buffer)
	   (al:buffer-data buffer :mono16 dubs (* 2 size) 44100)
	   (al:source source :buffer buffer)
	   (al:source-play source)
	   (read))))))

 (defun read-yolo (text)
   (let ((state :nope)
	 (text (cons " " (split-sequence:split-sequence #\newline text)))
	 acc)
     (dolist (item text)
       (if (equalp item " ")
	   (setf state :eat-next)
	   (progn
	     (when (eq state :eat-next)
	       (push (split-sequence:split-sequence #\tab item)
		     acc))
	     (setf state :full))))
     (nreverse acc)))

 (defun print-out (list)
   (let ((*print-case* :downcase))
     (dolist (item list)
       (let ((a (first item))
	     (b (second item)))
	 (princ "(")
	 (princ b)
	 (princ " ")
	 (let ((a2 (pase-tip a)))
	   (let* ((pointers (end-pointers? a2))
		  (type (get-item
			 (if (zerop pointers)
			     a2
			     (nbutlast a2)))))
	     (let ((acc type))
	       (dotimes (i pointers)
		 (setf acc (if t :pointer (list :pointer acc))))
	       (prin1 acc))))
	 (princ ")"))
       (terpri))))

 (defun pase-tip (string)
   (let ((values (split-sequence:split-sequence #\space string)))
     (setf values (delete-if
		   (lambda (x)
		     (or (equal x "")
			 (equal x "const")
			 (equal x "attribute_deprecated"))) values))
     values))

 (defun end-pointers? (list)
   (let ((item (car (last list))))
     (if (eql #\* (aref item 0))
	 (array-total-size item)
	 0)))

 (defparameter *c-types* (make-hash-table :test 'equal))
 (defun add-item (item keyword)
   (let ((items (split-sequence:split-sequence #\space item)))
     (setf (gethash items *c-types*) keyword)))
 (defun get-item (item)
   (if (equal "enum" (car item))
       :int
       (or (gethash item *c-types*)
	   (intern (car item)))))


 (mapcar #'(lambda (x) (add-item (first x)
				 (second x)))
	 (quote (("char" :char)
		 ("unsigned char" :unsigned-char)
		 ("short" :short)
		 ("unsigned short" :unsigned-short)
		 ("int" :int)
		 ("unsigned int" :uint)
		 ("long" :long)
		 ("unsigned long" :unsigned-long)
		 ("long long" :long-long)
		 ("unsigned long long" :unsigned-long-long)
		 ("float" :float)
		 ("double" :double)
		 ("int8_t" :int8)
		 ("int16_t" :int16)
		 ("int32_t" :int32)
		 ("int64_t" :int64)
		 ("uint8_t" :uint8)
		 ("uint16_t" :uint16)
		 ("uint32_t" :uint32)
		 ("uint64_t" :uint64)
		 ("void" :void)
		 ("unsigned" :unsigned-int)))))

(defcstruct |AVIOInterruptCB|
  (callback :pointer)
  (opaque :pointer))

(defcstruct |AVFormatContext|
  (av_class :pointer)
  (iformat :pointer)
  (oformat :pointer)
  (priv_data :pointer)
  (pb :pointer)
  (ctx_flags :int)
  (nb_streams :uint)
  (streams :pointer)
  (filename :char :count 1024)
  (start_time :int64)
  (duration :int64)
  (bit_rate :int64)
  (packet_size :uint)
  (max_delay :int)
  (flags :int)
  (probesize :int64)
  (max_analyze_duration :int64)
  (key :pointer)
  (keylen :int)
  (nb_programs :uint)
  (programs :pointer)
  (video_codec_id :int)
  (audio_codec_id :int)
  (subtitle_codec_id :int)
  (max_index_size :uint)
  (max_picture_buffer :uint)
  (nb_chapters :uint)
  (chapters :pointer)
  (metadata :pointer)
  (start_time_realtime :int64)
  (fps_probe_size :int)
  (error_recognition :int)
  (interrupt_callback (:struct |AVIOInterruptCB|))
  (debug :int)
  (max_interleave_delta :int64)
  (strict_std_compliance :int)
  (event_flags :int)
  (max_ts_probe :int)
  (avoid_negative_ts :int)
  (ts_id :int)
  (audio_preload :int)
  (max_chunk_duration :int)
  (max_chunk_size :int)
  (use_wallclock_as_timestamps :int)
  (avio_flags :int)
  (duration_estimation_method :int)
  (skip_initial_bytes :int64)
  (correct_ts_overflow :uint)
  (seek2any :int)
  (flush_packets :int)
  (probe_score :int)
  (format_probesize :int)
  (codec_whitelist :pointer)
  (format_whitelist :pointer)
  (internal :pointer)
  (io_repositioned :int)
  (video_codec :pointer)
  (audio_codec :pointer)
  (subtitle_codec :pointer)
  (data_codec :pointer)
  (metadata_header_padding :int)
  (opaque :pointer)
  (control_message_cb :pointer);;;what??!?
  (output_ts_offset :int64)
  (dump_separator :pointer)
  (data_codec_id :int)
  (protocol_whitelist :pointer)
  (io_open :pointer)
  (io_close :pointer))

(defcstruct |AVPacket|
  (buf :pointer)
  (pts :int64)
  (dts :int64)
  (data :pointer)
  (size :int)
  (stream_index :int)
  (flags :int)
  (side_data :pointer)
  (side_data_elems :int)
  (duration :int)
  (destruct  :pointer)
  (priv :pointer)
  (pos :int64)
  (convergence_duration :int64))

(defcstruct |AVRational|
  (num :int)
  (den :int))

(defcstruct |AVFrame|
  (data :pointer :count 8)
  (linesize :int :count 8)
  (extended_data :pointer)
  (width :int)
  (height :int)
  (nb_samples :int)
  (format :int)
  (key_frame :int)
  (pict_type :int)
  (sample_aspect_ratio (:struct |AVRational|))
  (pts :int64)
  (pkt_pts :int64)
  (pkt_dts :int64)
  (coded_picture_number :int)
  (display_picture_number :int)
  (quality :int)
  (opaque :pointer)
  (error :uint64 :count 8)
  (repeat_pict :int)
  (interlaced_frame :int)
  (top_field_first :int)
  (palette_has_changed :int)
  (reordered_opaque :int64)
  (sample_rate :int)
  (channel_layout :uint64)
  (buf :pointer :count 8)
  (extended_buf :pointer)
  (nb_extended_buf :int)
  (side_data :pointer)
  (nb_side_data :int)
  (flags :int)
  (color_range :int)
  (color_primaries :int)
  (color_trc :int)
  (colorspace :int)
  (chroma_location :int)
  (best_effort_timestamp :int64)
  (pkt_pos :int64)
  (pkt_duration :int64)
  (metadata :pointer)
  (decode_error_flags :int)
  (channels :int)
  (pkt_size :int)
  (qscale_table :pointer)
  (qstride :int)
  (qscale_type :int)
  (qp_table_buf :pointer))

(defcstruct |AudioData|
  (class :pointer)
  (data  :pointer :count 32)
  (buffer :pointer)
  (buffer_size :uint)
  (allocated_samples :int)
  (nb_samples :int)
  (sample_fmt :int)
  (channels :int)
  (allocated_channels :int)
  (is_planar :int)
  (planes :int)
  (sample_size :int)
  (stride :int)
  (read_only :int)
  (allow_realloc :int)
  (ptr_align :int)
  (samples_align :int)
  (name :pointer)
  (ch :pointer :count 32)
  (ch_count :int)
  (bps :int)
  (count :int)
  (planar :int)
  (fmt :int))

(defcstruct |DitherDSPContext|
  (quantize :pointer)
  (ptr_align :int)
  (samples-align :int)
  (dither_int_to_float :pointer))

(defcstruct |DitherContext|
  (ddsp (:struct |DitherDSPContext|))
  (method :int)
  (apply_map :int)
  (ch_map_info :pointer)
  (mute_dither_threshold :int)
  (mute_reset_threshold :int)
  (ns_coef_b :pointer)
  (ns_coef_a :pointer)
  (channels :int)
  (state :pointer)
  (flt_data :pointer)
  (s16_data :pointer)
  (ac_in :pointer)
  (ac_out :pointer)
  (quantize :pointer)
  (samples_align :int)
  (method :int)
  (noise_pos :int)
  (scale :float)
  (noise_scale :float)
  (ns_taps :int)
  (ns_scale :float)
  (ns_scale_1 :float)
  (ns_pos :int)
  (ns_coeffs :float :count 20)
  (ns_errors :float :count 1280)
  (noise (:struct |AudioData|))
  (temp (:struct |AudioData|))
  (output_sample_bits :int))

(defcstruct |SwrContext|
  (av_class :pointer)
  (log_level_offset :int)
  (log_ctx :pointer)
  (in_sample_fmt :int)
  (int_sample_fmt :int)
  (out_sample_fmt :int)
  (in_ch_layout :int64)
  (out_ch_layout :int64)
  (in_sample_rate :int)
  (out_sample_rate :int)
  (flags :int)
  (slev :float)
  (clev :float)
  (lfe_mix_level :float)
  (rematrix_volume :float)
  (rematrix_maxval :float)
  (matrix_encoding :int)
  (channel_map :pointer)
  (used_ch_count :int)
  (engine :int)
  (dither (:struct |DitherContext|))
  (filter_size :int)
  (phase_shift :int)
  (linear_interp :int)
  (cutoff :double)
  (filter_type :int)
  (kaiser_beta :int)
  (precision :double)
  (cheby :int)
  (min_compensation :float)
  (min_hard_compensation :float)
  (soft_compensation_duration :float)
  (max_soft_compensation :float)
  (async :float)
  (firstpts_in_samples :int64)
  (resample_first :int)
  (rematrix :int)
  (rematrix_custom :int)
  (in (:struct |AudioData|))
  (postin (:struct |AudioData|))
  (midbuf (:struct |AudioData|))
  (preout (:struct |AudioData|))
  (out (:struct |AudioData|))
  (in_buffer (:struct |AudioData|))
  (silence (:struct |AudioData|))
  (drop_temp (:struct |AudioData|))
  (in_buffer_index :int)
  (in_buffer_count :int)
  (resample_in_constraint :int)
  (flushed :int)
  (outpts :int64)
  (firstpts :int64)
  (drop_output :int)
  (in_convert :pointer)
  (out_convert :pointer)
  (full_convert :pointer)
  (resample :pointer)
  (resampler :pointer)
  (matrix :float :count 1024)
  (native_matrix :pointer)
  (native_one :pointer)
  (native_simd_one :pointer)
  (native_simd_matrix :pointer)
  (matrix32 :int32 :count 1024)
  (matrix_ch :uint8 :count 1056)
  (mix_1_1_f :pointer)
  (mix_1_1_simd :pointer)
  (mix_2_1_f :pointer)
  (mix_2_1_simd :pointer)
  (mix_any_f :pointer))

(defcstruct |AVCodecContext|
  (av_class :pointer)
  (log_level_offset :int)
  (codec_type :int)
  (codec :pointer)
  (codec_name :char :count 32)
  (codec_id :int)
  (codec_tag :uint)
  (stream_codec_tag :uint)
  (priv_data :pointer)
  (internal :pointer)
  (opaque :pointer)
  (bit_rate :int64)
  (bit_rate_tolerance :int)
  (global_quality :int)
  (compression_level :int)
  (flags :int)
  (flags2 :int)
  (extradata :pointer)
  (extradata_size :int)
  (time_base (:struct |AVRational|))
  (ticks_per_frame :int)
  (delay :int)
  (width :int)
  (height :int)
  (coded_width :int)
  (coded_height :int)
  (gop_size :int)
  (pix_fmt :int)
  (me_method :int)
  (draw_horiz_band :pointer)
  (get_format :pointer)
  (max_b_frames :int)
  (b_quant_factor :float)
  (rc_strategy :int)
  (b_frame_strategy :int)
  (b_quant_offset :float)
  (has_b_frames :int)
  (mpeg_quant :int)
  (i_quant_factor :float)
  (i_quant_offset :float)
  (lumi_masking :float)
  (temporal_cplx_masking :float)
  (spatial_cplx_masking :float)
  (p_masking :float)
  (dark_masking :float)
  (slice_count :int)
  (prediction_method :int)
  (slice_offset :pointer)
  (sample_aspect_ratio (:struct |AVRational|))
  (me_cmp :int)
  (me_sub_cmp :int)
  (mb_cmp :int)
  (ildct_cmp :int)
  (dia_size :int)
  (last_predictor_count :int)
  (pre_me :int)
  (me_pre_cmp :int)
  (pre_dia_size :int)
  (me_subpel_quality :int)
  (dtg_active_format :int)
  (me_range :int)
  (intra_quant_bias :int)
  (inter_quant_bias :int)
  (slice_flags :int)
  (mb_decision :int)
  (intra_matrix :pointer)
  (inter_matrix :pointer)
  (scenechange_threshold :int)
  (noise_reduction :int)
  (me_threshold :int)
  (mb_threshold :int)
  (intra_dc_precision :int)
  (skip_top :int)
  (skip_bottom :int)
  (border_masking :float)
  (mb_lmin :int)
  (mb_lmax :int)
  (me_penalty_compensation :int)
  (bidir_refine :int)
  (brd_scale :int)
  (keyint_min :int)
  (refs :int)
  (chromaoffset :int)
  (scenechange_factor :int)
  (mv0_threshold :int)
  (b_sensitivity :int)
  (color_primaries :int)
  (color_trc :int)
  (colorspace :int)
  (color_range :int)
  (chroma_sample_location :int)
  (slices :int)
  (field_order :int)
  (sample_rate :int)
  (channels :int)
  (sample_fmt :int)
  (frame_size :int)
  (frame_number :int)
  (block_align :int)
  (cutoff :int)
  (channel_layout :uint64)
  (request_channel_layout :uint64)
  (audio_service_type :int)
  (request_sample_fmt :int)
  (get_buffer2 :pointer)
  (refcounted_frames :int)
  (qcompress :float)
  (qblur :float)
  (qmin :int)
  (qmax :int)
  (max_qdiff :int)
  (rc_qsquish :float)
  (rc_qmod_amp :float)
  (rc_qmod_freq :int)
  (rc_buffer_size :int)
  (rc_override_count :int)
  (rc_override :pointer)
  (rc_eq :pointer)
  (rc_max_rate :int64)
  (rc_min_rate :int64)
  (rc_buffer_aggressivity :float)
  (rc_initial_cplx :float)
  (rc_max_available_vbv_use :float)
  (rc_min_vbv_overflow_use :float)
  (rc_initial_buffer_occupancy :int)
  (coder_type :int)
  (context_model :int)
  (lmin :int)
  (lmax :int)
  (frame_skip_threshold :int)
  (frame_skip_factor :int)
  (frame_skip_exp :int)
  (frame_skip_cmp :int)
  (trellis :int)
  (min_prediction_order :int)
  (max_prediction_order :int)
  (timecode_frame_start :int64)
  (rtp_callback :pointer)
  (rtp_payload_size :int)
  (mv_bits :int)
  (header_bits :int)
  (i_tex_bits :int)
  (p_tex_bits :int)
  (i_count :int)
  (p_count :int)
  (skip_count :int)
  (misc_bits :int)
  (frame_bits :int)
  (stats_out :pointer)
  (stats_in :pointer)
  (workaround_bugs :int)
  (strict_std_compliance :int)
  (error_concealment :int)
  (debug :int)
  (debug_mv :int)
  (err_recognition :int)
  (reordered_opaque :int64)
  (hwaccel :pointer)
  (hwaccel_context :pointer)
  (error :uint64 :count 8)
  (dct_algo :int)
  (idct_algo :int)
  (bits_per_coded_sample :int)
  (bits_per_raw_sample :int)
  (lowres :int)
  (coded_frame :pointer)
  (thread_count :int)
  (thread_type :int)
  (active_thread_type :int)
  (thread_safe_callbacks :int)
  (execute :pointer)
  (execute2 :pointer)
  (nsse_weight :int)
  (profile :int)
  (level :int)
  (skip_loop_filter :int)
  (skip_idct :int)
  (skip_frame :int)
  (subtitle_header :pointer)
  (subtitle_header_size :int)
  (error_rate :int)
  (vbv_delay :uint64)
  (side_data_only_packets :int)
  (initial_padding :int)
  (framerate (:struct |AVRational|))
  (sw_pix_fmt :int)
  (pkt_timebase (:struct |AVRational|))
  (codec_descriptor :pointer)
  (pts_correction_num_faulty_pts :int64)
  (pts_correction_num_faulty_dts :int64)
  (pts_correction_last_pts :int64)
  (pts_correction_last_dts :int64)
  (sub_charenc :pointer)
  (sub_charenc_mode :int)
  (skip_alpha :int)
  (seek_preroll :int)
  (chroma_intra_matrix :pointer)
  (dump_separator :pointer)
  (codec_whitelist :pointer)
  (properties :unsigned-int)
  (coded_side_data :pointer)
  (nb_coded_side_data :int)
  (hw_frames_ctx :pointer)
  (sub_text_format :int)
  (trailing_padding :int))

(defcstruct |AVStream-aux|
  (last_dts :int64)
  (duration_gcd :int64)
  (duration_count :int)
  (rfps_duration_sum :int64)
  (duration_error :double)
  (codec_info_duration :int64)
  (codec_info_duration_fields :int64)
  (found_decoder :int)
  (last_duration :int64)
  (fps_first_dts :int64)
  (fps_first_dts_idx :int)
  (fps_last_dts :int64)
  (fps_last_dts_idx :int))

(defcstruct |AVProbeData|
  (filename :pointer)
  (buf :pointer)
  (buf_size :int)
  (mime_type :pointer))

(defcstruct |AVStream|
  (index :int)
  (id :int)
  (codec :pointer)
  (priv_data :pointer)
  (time_base (:struct |AVRational|))
  (start_time :int64)
  (duration :int64)
  (nb_frames :int64)
  (disposition :int)
  (discard :int)
  (sample_aspect_ratio (:struct |AVRational|))
  (metadata :pointer)
  (avg_frame_rate (:struct |AVRational|))
  (attached_pic (:struct |AVPacket|))
  (side_data :pointer)
  (nb_side_data :int)
  (event_flags :int)
  (info (:struct |AVStream-aux|))
  (pts_wrap_bits :int)
  (first_dts :int64)
  (cur_dts :int64)
  (last_IP_pts :int64)
  (last_IP_duration :int)
  (probe_packets :int)
  (codec_info_nb_frames :int)
  (need_parsing :int)
  (parser :pointer)
  (last_in_packet_buffer :pointer)
  (probe_data (:struct |AVProbeData|))
  (pts_buffer :int64 :count 17)
  (index_entries :pointer)
  (nb_index_entries :int)
  (index_entries_allocated_size :uint)
  (r_frame_rate (:struct |AVRational|))
  (stream_identifier :int)
  (interleaver_chunk_size :int64)
  (interleaver_chunk_duration :int64)
  (request_probe :int)
  (skip_to_keyframe :int)
  (skip_samples :int)
  (start_skip_samples :int64)
  (first_discard_sample :int64)
  (last_discard_sample :int64)
  (nb_decoded_frames :int)
  (mux_ts_offset :int64)
  (pts_wrap_reference :int64)
  (pts_wrap_behavior :int)
  (update_initial_durations_done :int)
  (pts_reorder_error :int64 :count 17)
  (pts_reorder_error_count :uint8 :count 17)
  (last_dts_for_order_check :int64)
  (dts_ordered :uint8)
  (dts_misordered :uint8)
  (inject_global_side_data :int)
  (recommended_encoder_configuration :pointer)
  (display_aspect_ratio (:struct |AVRational|))
  (priv_pts :pointer)
  (internal :pointer))

(defcfun ("av_register_all" av-register-all)
    :void)
(defcfun ("avformat_alloc_context" avformat-alloc-context)
    (:pointer (:struct |AVFormatContext|)))
(defcfun ("avformat_open_input" avformat-open-input)
    :int
  (ps :pointer)
  (filename :pointer)
  (fmt :pointer)
  (options :pointer))
(defcfun ("avformat_find_stream_info" avformat-find-stream-info)
    :int
  (ic :pointer)
  (options :pointer))
(defcfun ("avcoded_open2" avcodec-open2)
    :int
  (avctx :pointer)
  (codec :pointer)
  (options :pointer))

(defcfun ("avcodec_find_decoder" avcodec-find-decoder)
    :pointer
  (id :int))

(defcfun ("av_opt_set_int" av-opt-set-int)
    :int
  (obj :pointer)
  (name :pointer)
  (val :double)
  (search_flags :int))
(defcfun ("av_opt_set_sample_fmt" av-opt-set-sample-fmt)
    :int
  (obj :pointer)
  (name :pointer)
  (fmt :int)
  (search_flags :int))

(defcfun ("swr_init" swr-init)
    :int
  (s :pointer))
(defcfun ("swr_is_initialized" swr-is-initialized)
    :int
  (s :pointer))
(defcfun ("av_init_packet" av-init-packet)
    :void
  (s :pointer))

(defcfun ("av_frame_alloc" av-frame-alloc)
    :pointer)
(defcfun ("av_read_frame" av-read-frame)
    :int
  (s :pointer)
  (pkt :pointer))
(defcfun ("avcodec_decode_audio4" avcodec-decode-audio4)
    :int
  (avctx :pointer)
  (frame :pointer)
  (got_picture_ptr :pointer)
  (avpkt :pointer))

(defcfun ("av_samples_alloc" av-samples-alloc)
    :int
  (audio_data :pointer)
  (linesize :pointer)
  (buf :pointer)
  (nb_channels :int)
  (nb_samples :int)
  (sample_fmt :int)
  (align :int))

(defcfun ("swr_convert" swr-convert)
    :int
  (s :pointer)
  (out :pointer)
  (out_count :int)
  (in :pointer)
  (in_count :int))

(defcfun ("realloc" realloc)
    :void
  (ptr :pointer)
  (size :uint))

(defcfun ("memcpy" memcpy)
    :void
  (str1 :pointer)
  (str2 :pointer)
  (n :uint))

(defcfun ("av_frame_free" av-frame-free)
    :void
  (frame :pointer))
(defcfun ("swr_free" swr-free)
    :void
  (s :pointer))
(defcfun ("avcodec_close" avcodec-close)
    :int
  (avctx :pointer))
(defcfun ("avformat_free_context" avformat-free-context)
    :void
  (s :pointer))

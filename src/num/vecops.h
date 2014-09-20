/* Copyright 2013-2014. The Regents of the University of California.
 * All rights reserved. Use of this source code is governed by 
 * a BSD-style license which can be found in the LICENSE file.
 */

#ifndef __VECOPS_H
#define __VECOPS_H

extern const struct vec_ops cpu_ops;

struct vec_ops {

	float* (*allocate)(long N);
	void (*del)(float* vec);
	void (*clear)(long N, float* vec);
	void (*copy)(long N, float* dst, const float* src);
	void (*float2double)(long N, double* dst, const float* src);
	void (*double2float)(long N, float* dst, const double* src);
	void (*axpy)(long N, float* dst, float alpha, const float* src);
	void (*xpay)(long N, float beta, float* dst, const float* src);
	void (*smul)(long N, float alpha, float* dst, const float* src);
	double (*dot)(long N, const float* vec1, const float* vec2);
	double (*norm)(long N, const float* vec);
	double (*asum)(long N, const float* vec);
	double (*zl1norm)(long N, const _Complex float* vec);

	void (*pow)(long N, float* dst, const float* src1, const float* src2);
	void (*sqrt)(long N, float* dst, const float* src);

	void (*le)(long N, float* dst, const float* src1, const float* src2);

	void (*add)(long N, float* dst, const float* src1, const float* src2);
	void (*sub)(long N, float* dst, const float* src1, const float* src2);
	void (*mul)(long N, float* dst, const float* src1, const float* src2);
	void (*div)(long N, float* dst, const float* src1, const float* src2);
	void (*fmac)(long N, float* dst, const float* src1, const float* src2);
	void (*fmac2)(long N, double* dst, const float* src1, const float* src2);

	void (*zmul)(long N, _Complex float* dst, const _Complex float* src1, const _Complex float* src2);
	void (*zdiv)(long N, _Complex float* dst, const _Complex float* src1, const _Complex float* src2);
	void (*zfmac)(long N, _Complex float* dst, const _Complex float* src1, const _Complex float* src2);
	void (*zfmac2)(long N, _Complex double* dst, const _Complex float* src1, const _Complex float* src2);
	void (*zmulc)(long N, _Complex float* dst, const _Complex float* src1, const _Complex float* src2);
	void (*zfmacc)(long N, _Complex float* dst, const _Complex float* src1, const _Complex float* src2);
	void (*zfmacc2)(long N, _Complex double* dst, const _Complex float* src1, const _Complex float* src2);

	void (*zpow)(long N,  _Complex float* dst, const _Complex float* src1, const _Complex float* src2);
	void (*zphsr)(long N, _Complex float* dst, const _Complex float* src);
	void (*zconj)(long N, _Complex float* dst, const _Complex float* src);

	void (*zcmp)(long N, _Complex float* dst, const _Complex float* src1, const _Complex float* src2);
	void (*zdiv_reg)(long N, _Complex float* dst, const _Complex float* src1, const _Complex float* src2, _Complex float lambda);


	void (*maxxy)(long N, float* dst, const float* src);
	void (*minxy)(long N, float* dst, const float* src);

	void (*zsoftthresh_half)(long N, float lambda,  _Complex float* dst, const _Complex float* src);
	void (*zsoftthresh)(long N, float lambda,  _Complex float* dst, const _Complex float* src);
	void (*softthresh_half)(long N, float lambda,  float* dst, const float* src);
	void (*softthresh)(long N, float lambda,  float* dst, const float* src);
	void (*swap)(long N, float* a, float* b);

};


#endif

